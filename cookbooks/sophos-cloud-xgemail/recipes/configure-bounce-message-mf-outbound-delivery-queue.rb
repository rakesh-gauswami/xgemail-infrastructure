#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-bounce-message-mf-outbound-delivery-queue
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures bounce delivery settings in  main.cf at
# internet delivery and extended internet delivery postfix instance
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

TRANSPORT_MAPS_FILENAME = 'transport_maps'

SERVICE_NAME='bounce-handler'

MF_OUTBOUND_DELIVERY_BOUNCE_MESSAGE_PROCESSOR_DIR = node['xgemail']['mf_outbound_delivery_message_bouncer_processor_dir']
MF_OUTBOUND_DELIVERY_BOUNCE_MESSAGE_PROCESSOR_COMMON_DIR  = node['xgemail']['mf_outbound_delivery_message_bouncer_common_dir']

BOUNCE_HANDLER_SCRIPT = 'xgemail.message.bouncer.py'
NOTIFICATION_EVENT_FILE_NAME = 'notificationsubmitinfo.py'
BOUNCE_HANDLER_SCRIPT_PATH = "#{MF_OUTBOUND_DELIVERY_BOUNCE_MESSAGE_PROCESSOR_DIR}/#{BOUNCE_HANDLER_SCRIPT}"
AWS_REGION = node['sophos_cloud']['region']
ACCOUNT    = node['sophos_cloud']['context']

# Exit codes from sysexits
EX_TEMPFAIL = node['xgemail']['temp_failure_code']

XGEMAIL_UTILS_DIR = node['xgemail']['xgemail_utils_files_dir']
XGEMAIL_NOTIFIER_QUEUE_URL = node['xgemail']['msg_notifier_queue_url']

if NODE_TYPE == 'mf-outbound-delivery' || NODE_TYPE == 'mf-outbound-xdelivery'

  CONFIGURATION_COMMANDS_DELIVER_BOUNCE =
    [
      'notify_classes=bounce, resource, software',
      'bounce_notice_recipient=bounces@sophos-email.com',
      'xgemail_do_sender_bounce = no',
      'xgemail_suppress_2bounce = yes',
      "transport_maps=hash:$config_directory/#{TRANSPORT_MAPS_FILENAME}",
      "maximal_queue_lifetime=5d"
    ]

  # Rehash transport map
  execute TRANSPORT_MAPS_FILENAME do
    command lazy {
      print_postmulti_cmd(
        INSTANCE_NAME,
        "postmap 'hash:#{postmulti_config_dir(INSTANCE_NAME)}/#{TRANSPORT_MAPS_FILENAME}'"
      )
    }
    action :nothing
  end

  # Configure Postfix
  # This master.cf configuration pipes information to bounce-handler script
  SERVICE_TYPE='unix'
  BOUNCE_USER=node['xgemail']['mf_outbound_delivery_bounce_message_processor_user']
  SCRIPT_PATH="#{BOUNCE_HANDLER_SCRIPT_PATH}"
  CONCURRENCY_LIMIT=10

  # Create user for bounce message processing
  user BOUNCE_USER do
    system true
    shell '/sbin/nologin'
  end

  PIPE_COMMAND='pipe ' +
    'flags=hqu ' +
    "user=#{BOUNCE_USER} " +
    "argv=#{SCRIPT_PATH} " +
    '${sender} ' +
    '${client_address} ' +
    '${queue_id} ' +
    '${nexthop} ' +
    '${original_recipient}'

  # Install new pipe service into master
  [
    "#{SERVICE_NAME}/#{SERVICE_TYPE} = #{SERVICE_NAME} #{SERVICE_TYPE} - n n - #{CONCURRENCY_LIMIT} #{PIPE_COMMAND}"
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf -M '#{cur}'" )
  end

  file TRANSPORT_MAPS_FILENAME do
    path lazy { "#{postmulti_config_dir(INSTANCE_NAME)}/#{TRANSPORT_MAPS_FILENAME}" }
    transport_content = "bounces@sophos-email.com #{SERVICE_NAME}:\n"
    sandbox_transport_content = ''
    if ACCOUNT == 'sandbox'
      sandbox_transport_content = "#{node['sandbox']['mail_transport_entry']}\n"
    end
    content sandbox_transport_content + transport_content
    notifies :run, "execute[#{TRANSPORT_MAPS_FILENAME}]", :immediately
  end

  # Configure main.cf
  CONFIGURATION_COMMANDS_DELIVER_BOUNCE.each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf -e '#{cur}'" )
  end

  # Create directory for bounce-handler script
  directory MF_OUTBOUND_DELIVERY_BOUNCE_MESSAGE_PROCESSOR_DIR do
    owner BOUNCE_USER
    group BOUNCE_USER
    mode '0755'
    recursive true
    action :create
  end

  # Create directory for bounce-handler script
  directory MF_OUTBOUND_DELIVERY_BOUNCE_MESSAGE_PROCESSOR_COMMON_DIR do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end

  # Ensure __init__py file is created in python module
  file "#{MF_OUTBOUND_DELIVERY_BOUNCE_MESSAGE_PROCESSOR_COMMON_DIR}/__init__.py" do
    mode '0644'
    owner 'root'
    group 'root'
  end

  # Create notification event file.
  cookbook_file "#{MF_OUTBOUND_DELIVERY_BOUNCE_MESSAGE_PROCESSOR_COMMON_DIR}/#{NOTIFICATION_EVENT_FILE_NAME}" do
    source NOTIFICATION_EVENT_FILE_NAME
    mode  '0644'
    owner 'root'
    group 'root'
  end

  # Add rsyslog config file to redirect messagebouncer messages to its own log file.
  file '/etc/rsyslog.d/00-xgemail-messagebouncer.conf' do
    content "if $syslogtag == '[messagebouncer]' then /var/log/xgemail/messagebouncer.log\n& ~"
    mode '0600'
    owner 'root'
    group 'root'
  end

  template BOUNCE_HANDLER_SCRIPT_PATH do
    source 'xgemail.message.bouncer.py.erb'
    mode  '0700'
    owner BOUNCE_USER
    group BOUNCE_USER
    variables(
      :aws_region => AWS_REGION,
      :ex_tempfail_code => EX_TEMPFAIL,
      :utils_dir => XGEMAIL_UTILS_DIR,
      :notifier_sqs_url => XGEMAIL_NOTIFIER_QUEUE_URL
    )
  end
end