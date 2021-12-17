#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_outbound
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure Xgemail Jilter service for outbound email processing
#

package 'tar'
AWS_REGION = node['sophos_cloud']['region']
CENTRAL_VPC_ID = node['xgemail']['station_vpc_id']

instance_type=`echo $INSTANCE_TYPE`
NODE_TYPE = node['xgemail']['cluster_type']
ACCOUNT = node['sophos_cloud']['environment']

# Make sure we're on an customer submit node
if NODE_TYPE != 'customer-submit' && NODE_TYPE != 'jilter-outbound' && NODE_TYPE != 'mf-outbound-submit'
  return
end

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

DEPLOYMENT_DIR = node['xgemail']['xgemail_files_dir']
PACKAGES_DIR = '/opt/sophos/packages'

LIBSPF_JNI_VERSION = node['xgemail']['libspfjni']
LIBDKIM_JNI_VERSION = node['xgemail']['libdkimjni']

JILTER_SERVICE_NAME = node['xgemail']['jilter_service_name']
JILTER_PACKAGE_NAME = 'xgemail-jilter-outbound'
JILTER_SCRIPT_DIR = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/scripts"
JILTER_SCRIPT_PATH = "#{JILTER_SCRIPT_DIR}/xgemail.jilter.service.sh"
JILTER_CONF_DIR = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/conf"
JILTER_APPLICATION_PROPERTIES_PATH = "#{JILTER_CONF_DIR}/jilter-application.properties"

NODE_IP = node['ipaddress']
MSG_HISTORY_V2_STREAM_NAME = node['xgemail']['msg_history_v2_stream_name']
MSG_HISTORY_V2_BUCKET_NAME = node['xgemail']['msg_history_v2_bucket_name']
MSG_HISTORY_EVENT_DIR = node['xgemail']['mh_event_storage_dir']
MSG_HISTORY_EVENT_PROCESSOR_POOL_SIZE = node['xgemail']['mh_event_processor_pool_size']
MSG_HISTORY_EVENT_PROCESSOR_PORT = node['xgemail']['mh_event_processor_port']

LIBOPENDKIM_VERSION = node['xgemail']['libopendkim_version']
LIBOPENDKIM_PACKAGE_NAME = "libopendkim-#{LIBOPENDKIM_VERSION}"

SERVICE_USER = node['xgemail']['jilter_user']
POLICY_BUCKET_NAME   = node['xgemail']['xgemail_policy_bucket_name']
ACTIVE_PROFILE = node['xgemail']['xgemail_active_profile']

CUSTOMER_SUBMIT_BUCKET_NAME = node['xgemail']['xgemail_bucket_name']

if ACCOUNT == 'sandbox'
  include_recipe 'sophos-cloud-xgemail::install_jilter_code_sandbox'
  include_recipe 'sophos-cloud-xgemail::install_jilter_common'
else
  include_recipe 'sophos-cloud-xgemail::install_jilter_common'
end

if ACCOUNT == 'prod'
  REFLEXION_RELAY_ALLOW_IPS = '208.70.208.0/22'
else
  REFLEXION_RELAY_ALLOW_IPS = '208.70.208.0/22,52.11.211.86,52.26.62.6'
end
# Modify /etc/rsyslog.conf
execute 'modify_rsyslog.conf' do
  user 'root'
  command <<-EOH
      sed -i -e 's/#\$ModLoad\simudp/\$ModLoad imudp/' /etc/rsyslog.conf \
      -e 's/#\$UDPServerRun\s514/\$UDPServerRun 514/' /etc/rsyslog.conf
  EOH
end

# Add rsyslog config file to redirect jilter messages to its own log file.
file "/etc/rsyslog.d/00-#{JILTER_PACKAGE_NAME}.conf" do
  content "if $syslogtag == '[#{JILTER_PACKAGE_NAME}]' and $syslogseverity <= '6' then /var/log/xgemail/jilter.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end

# Move libspfjni to not have a version so Java can find it
execute 'move_jilter_jni' do
  user 'root'
  cwd DEPLOYMENT_DIR
  command <<-EOH
      mv #{JILTER_PACKAGE_NAME}/lib/libspfjni-#{LIBSPF_JNI_VERSION}.so #{JILTER_PACKAGE_NAME}/lib/libspfjni.so
  EOH
end

# Install libopendkim package via yum
execute "execute_yum_dkim_install" do
  user "root"
  cwd "/tmp"
  command <<-EOH
      yum install -y #{LIBOPENDKIM_PACKAGE_NAME}
  EOH
end

# dkim jni movement
# temporarily hard-coded the xgemail-jilter-inbound path. As part of XGE-6573 the
# jilter-outbound service will build the libdkimjni itself
src = "#{DEPLOYMENT_DIR}/xgemail-jilter-inbound/lib/libdkimjni-#{LIBDKIM_JNI_VERSION}.so"

log "filename_information" do
  message "dkim jni library is: #{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/lib/libdkimjni-#{LIBDKIM_JNI_VERSION}.so"
  level :debug
end

src_url = "file://#{src}"
dest_location = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/lib/libdkimjni.so"

remote_file "move_dkim_jni" do
  path dest_location
  source src_url
  owner 'root'
  action :create
end

# Remove the dkim library
file "#{src}" do
  action :delete
end

# Create the jilter script directory
directory JILTER_SCRIPT_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

# Create the jilter application properties directory
directory JILTER_CONF_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end


# Create jilter user
user SERVICE_USER do
  system true
  shell '/sbin/nologin'
end


if ACCOUNT != 'sandbox'

  # Give ownership to the jilter service user
  file "#{JILTER_CONF_DIR}/launch_darkly_#{ACCOUNT}.properties" do
    owner SERVICE_USER
    group SERVICE_USER
    action :touch
  end

  # Create dir where Jilter writes accepted events temporarily for producers to read.
  directory MSG_HISTORY_EVENT_DIR do
    mode '0755'
    owner SERVICE_USER
    group SERVICE_USER
    recursive true
  end

  # configure logrotate for jilter
  template 'xgemail-jilter-logrotate' do
    path "/etc/logrotate.d/jilter"
    source 'xgemail.jilter.logrotate.erb'
    mode '0644'
    owner 'root'
    group 'root'
  end

  # Create the Jilter service
  template 'xgemail.jilter.service.sh' do
    path JILTER_SCRIPT_PATH
    source 'xgemail.jilter.outbound.service.sh.erb'
    mode '0700'
    owner SERVICE_USER
    group SERVICE_USER
    variables(
        :deployment_dir => DEPLOYMENT_DIR,
        :active_profile => ACTIVE_PROFILE
    )
  end


  # Create the jilter application properties
  template 'xgemail.jilter.properties' do
    path JILTER_APPLICATION_PROPERTIES_PATH
    source 'jilter-outbound-application.properties.erb'
    mode '0700'
    owner SERVICE_USER
    group SERVICE_USER
    variables(
        :aws_region => AWS_REGION,
        :central_vpc_id => CENTRAL_VPC_ID,
        :policy_bucket => POLICY_BUCKET_NAME,
        :account => ACCOUNT,
        :customer_submit_bucket => CUSTOMER_SUBMIT_BUCKET_NAME,
        :reflexion_relay_allow_ips => REFLEXION_RELAY_ALLOW_IPS,
        :node_ip => NODE_IP,
        :msg_history_v2_stream_name => MSG_HISTORY_V2_STREAM_NAME,
        :msg_history_v2_bucket_name => MSG_HISTORY_V2_BUCKET_NAME,
        :msg_history_event_dir => MSG_HISTORY_EVENT_DIR,
        :msg_history_event_processor_pool_size => MSG_HISTORY_EVENT_PROCESSOR_POOL_SIZE,
        :msg_history_event_processor_port => MSG_HISTORY_EVENT_PROCESSOR_PORT
    )
  end

  template 'xgemail-jilter-service' do
    path "/etc/init.d/#{JILTER_SERVICE_NAME}"
    source 'xgemail.jilter.service.init.erb'
    mode '0755'
    owner 'root'
    group 'root'
    variables(
        :service => JILTER_SERVICE_NAME,
        :script_path => JILTER_SCRIPT_PATH,
        :user => SERVICE_USER
    )
  end

  service 'xgemail-jilter-service' do
    service_name JILTER_SERVICE_NAME
    init_command "/etc/init.d/#{JILTER_SERVICE_NAME}"
    supports :restart => true, :start => true, :stop => true, :reload => true
    subscribes :enable, 'template[xgemail-jilter-service]', :immediately
  end

  # Update postfix to call jilter
  [
      'smtpd_milters = inet:localhost:9876',
      'milter_connect_macros = {client_addr}, {j}',
      'milter_mail_macros = {mail_addr}, {mail_host), {tls_version}',
      'milter_end_of_data_macros = {i}'
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end

else

  APPLICATION = node['xgemail']['application']
  DIRECTION   = node['xgemail']['direction']

  # Create the Jilter service
  template 'xgemail.jilter.service.sh' do
    path JILTER_SCRIPT_PATH
    source 'xgemail.jilter.sandbox.sh.erb'
    mode '0700'
    owner SERVICE_USER
    group SERVICE_USER
    variables(
        :deployment_dir => DEPLOYMENT_DIR,
        :property_path  => JILTER_APPLICATION_PROPERTIES_PATH,
        :active_profile => ACTIVE_PROFILE,
        :direction      => DIRECTION,
        :application    => APPLICATION
    )
  end

end
