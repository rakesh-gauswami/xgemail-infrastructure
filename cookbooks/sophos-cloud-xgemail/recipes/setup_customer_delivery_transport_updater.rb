#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_customer_delivery_transport_updater
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs cron job to pull domain routing information from PIC
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

ACCOUNT               = node['sophos_cloud']['environment']
ACCOUNT_NAME          = node['sophos_cloud']['account_name']
LOCAL_CERT_PATH       = node['sophos_cloud']['local_cert_path']
REGION                = node['sophos_cloud']['region']
CONNECTIONS_BUCKET    = node['sophos_cloud']['connections']

CRON_JOB_TIMEOUT      = node['xgemail']['cron_job_timeout']
CRON_MINUTE_FREQUENCY = node['xgemail']['customer_delivery_transport_cron_minute_frequency']
STATION_VPC_NAME      = node['xgemail']['station_vpc_name']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']
TRANSPORT_FILENAME    = 'transport'
INSTANCE_ID           = node['ec2']['instance_id']
MAIL_PIC_API_RESPONSE_TIMEOUT = node['xgemail']['mail_pic_apis_response_timeout_seconds']
MAIL_PIC_API_AUTH     = node['xgemail']['mail_pic_api_auth']
POLICY_BUCKET         = node['xgemail']['xgemail_policy_bucket_name']
ENC_CONFIG_KEY        = node['xgemail']['enc_config_key']
ENC_CONFIG_PREFIX_KEY = node['xgemail']['enc_config_prefix_key']
INBOUND_TLS_CONFIG_KEY = node['xgemail']['inbound_tls_config_key']
XGEMAIL_UTILS_DIR      = node['xgemail']['xgemail_utils_files_dir']
CUSTOM_ROUTE_TRANSPORT_PATH  = node['xgemail']['custom_route_transport_path']
FLAT_FILE_INSTANCE_LIST_PATH = node['xgemail']['flat_file_instance_path']

CONFIGURATION_COMMANDS =
  [
    "transport_maps=hash:$config_directory/#{TRANSPORT_FILENAME}"
  ]

if ACCOUNT == 'sandbox'
  TRANSPORT_FILE = "/etc/#{instance_name(INSTANCE_NAME)}/#{TRANSPORT_FILENAME}"
  file TRANSPORT_FILE do
    content "#{node['sandbox']['mail_transport_entry']}\n"
    mode '0644'
    owner 'root'
  end
  CONFIGURATION_COMMANDS.each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end

  execute 'build_postmap_for_transport' do
    user 'root'
    command <<-EOH
          postmap #{TRANSPORT_FILE}
    EOH
  end

  # Return, don't create CRON job
  return

end

PACKAGE_DIR                    = "#{XGEMAIL_FILES_DIR}/customer-delivery-transport"
TRANSPORT_UPDATER_SCRIPT       = 'customer.delivery.transport.updater.py'
TRANSPORT_UPDATER_SCRIPT_PATH  = "#{PACKAGE_DIR}/#{TRANSPORT_UPDATER_SCRIPT}"
if ACCOUNT_NAME == 'legacy'
  XGEMAIL_PIC_FQDN = "mail-#{STATION_VPC_NAME.downcase}-#{REGION}.#{ACCOUNT}.hydra.sophos.com"
else
  XGEMAIL_PIC_FQDN = "mail.#{node['sophos_cloud']['parent_account_name']}.ctr.sophos.com"
end
TRANSPORT_UPDATER_SERVICE_NAME = node['xgemail']['transport_updater']

directory XGEMAIL_FILES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end



template TRANSPORT_UPDATER_SCRIPT_PATH do
  source "#{TRANSPORT_UPDATER_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :xgemail_pic_fqdn => XGEMAIL_PIC_FQDN,
    :postfix_instance_name => instance_name( INSTANCE_NAME ),
    :transport_filename => TRANSPORT_FILENAME,
    :mail_pic_api_response_timeout => MAIL_PIC_API_RESPONSE_TIMEOUT,
    :mail_pic_api_auth => MAIL_PIC_API_AUTH,
    :connections_bucket => CONNECTIONS_BUCKET,
    :policy_bucket => POLICY_BUCKET,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR,
    :custom_route_transport_path => CUSTOM_ROUTE_TRANSPORT_PATH,
    :enc_config_key => ENC_CONFIG_KEY,
    :enc_config_prefix_key => ENC_CONFIG_PREFIX_KEY,
    :inbound_tls_config_key => INBOUND_TLS_CONFIG_KEY,
    :aws_region => REGION,
    :instance_id => INSTANCE_ID,
    :flat_file_instance_list_path => FLAT_FILE_INSTANCE_LIST_PATH
  )
  notifies :run, "execute[#{TRANSPORT_UPDATER_SCRIPT_PATH}]", :immediately
end

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end

# Run once manually
execute TRANSPORT_UPDATER_SCRIPT_PATH do
  ignore_failure true
  user 'root'
  action :nothing
end

template 'xgemail-transport-updater' do
  path "/etc/init.d/#{TRANSPORT_UPDATER_SERVICE_NAME}"
  source 'xgemail.transport.updater.init.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables(
    :service => TRANSPORT_UPDATER_SERVICE_NAME,
    :script_path => TRANSPORT_UPDATER_SCRIPT_PATH,
    :user => 'root'
  )
end

# Add rsyslog config file to redirect transportupdater messages to its own log file.
file '/etc/rsyslog.d/00-xgemail-transportupdater.conf' do
  content "if $syslogtag == '[cd-transport-updater]' then /var/log/xgemail/transportupdater.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end

service 'xgemail-transport-updater' do
  service_name TRANSPORT_UPDATER_SERVICE_NAME
  init_command "/etc/init.d/#{TRANSPORT_UPDATER_SERVICE_NAME}"
  supports :restart => true, :start => true, :stop => true, :reload => true
  subscribes :enable, 'template[xgemail-transport-updater]', :immediately
  action :start
end