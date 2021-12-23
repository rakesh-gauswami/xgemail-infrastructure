#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_delivery
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure Xgemail Jilter service for delivery servers
#

package 'tar'
REGION = node['sophos_cloud']['region']
STATION_VPC_ID = node['xgemail']['station_vpc_id']

NODE_TYPE = node['xgemail']['cluster_type']
ACCOUNT = node['sophos_cloud']['environment']

# Make sure we're on a delivery node
if NODE_TYPE != 'customer-delivery' && NODE_TYPE != 'xdelivery' &&
  NODE_TYPE != 'internet-delivery' && NODE_TYPE != 'internet-xdelivery' &&
  NODE_TYPE != 'risky-delivery' && NODE_TYPE != 'risky-xdelivery' &&
  NODE_TYPE != 'warmup-delivery' && NODE_TYPE != 'warmup-xdelivery' &&
  NODE_TYPE != 'beta-delivery' && NODE_TYPE != 'beta-xdelivery' &&
  NODE_TYPE != 'delta-delivery' && NODE_TYPE != 'delta-xdelivery' &&
  NODE_TYPE != 'encryption-delivery' && NODE_TYPE != 'mf-inbound-delivery' &&
  NODE_TYPE != 'mf-outbound-delivery' && NODE_TYPE != 'mf-inbound-xdelivery' &&
  NODE_TYPE != 'mf-outbound-xdelivery'
  return
end


INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

SERVER_TYPE = INSTANCE_DATA[:server_type]
raise "Invalid server type for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

DEPLOYMENT_DIR = node['xgemail']['xgemail_files_dir']
PACKAGES_DIR = '/opt/sophos/packages'

JILTER_SERVICE_NAME = node['xgemail']['jilter_service_name']
JILTER_PACKAGE_NAME = 'xgemail-jilter-delivery'
JILTER_SCRIPT_DIR = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/scripts"
JILTER_SCRIPT_PATH = "#{JILTER_SCRIPT_DIR}/xgemail.jilter.service.sh"
JILTER_CONF_DIR = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/conf"
JILTER_APPLICATION_PROPERTIES_PATH = "#{JILTER_CONF_DIR}/jilter-application.properties"

SERVER_IP = node['ipaddress']

MH_MAIL_INFO_STORAGE_DIR  = node['xgemail']['mh_mail_info_storage_dir']
MSG_HISTORY_DYNAMODB_TABLE_NAME = node['xgemail']['msg_history_dynamodb_table_name']
MSG_HISTORY_V2_STREAM_NAME = node['xgemail']['msg_history_v2_stream_name']
MSG_HISTORY_V2_BUCKET_NAME = node['xgemail']['msg_history_v2_bucket_name']
MSG_HISTORY_V2_DYNAMODB_TABLE_NAME = node['xgemail']['msg_history_v2_dynamodb_table_name']

AWS_REGION = node['sophos_cloud']['region']
SERVICE_USER = node['xgemail']['jilter_user']
POLICY_BUCKET_NAME   = node['xgemail']['xgemail_policy_bucket_name']
ACTIVE_PROFILE = node['xgemail']['xgemail_active_profile']

MSG_HISTORY_EVENT_PROCESSOR_POOL_SIZE = node['xgemail']['mh_event_processor_pool_size']
MSG_HISTORY_EVENT_PROCESSOR_PORT = node['xgemail']['mh_event_processor_port']

include_recipe 'sophos-cloud-xgemail::install_jilter_common'

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

# Give ownership to the jilter service user
file "#{JILTER_CONF_DIR}/launch_darkly_#{ACCOUNT}.properties" do
  owner SERVICE_USER
  group SERVICE_USER
  action :touch
end

# Create the Jilter service
template 'xgemail.jilter.service.sh' do
  path JILTER_SCRIPT_PATH
  source 'xgemail.jilter.delivery.service.sh.erb'
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
  source 'jilter-delivery-application.properties.erb'
  mode '0700'
  owner SERVICE_USER
  group SERVICE_USER
  variables(
      :account => ACCOUNT,
      :server_type => SERVER_TYPE,
      :server_ip => SERVER_IP,
      :mh_mail_info_storage_dir => MH_MAIL_INFO_STORAGE_DIR,
      :msg_history_v2_stream_name => MSG_HISTORY_V2_STREAM_NAME,
      :msg_history_v2_bucket_name => MSG_HISTORY_V2_BUCKET_NAME,
      :msg_history_v2_dynamodb_table_name =>  MSG_HISTORY_V2_DYNAMODB_TABLE_NAME,
      :msg_history_event_processor_pool_size => MSG_HISTORY_EVENT_PROCESSOR_POOL_SIZE,
      :msg_history_event_processor_port => MSG_HISTORY_EVENT_PROCESSOR_PORT,
      :policy_bucket => POLICY_BUCKET_NAME,
      :region => REGION,
      :station_vpc_id => STATION_VPC_ID
  )
end

# configure logrotate for jilter
template 'xgemail-jilter-logrotate' do
  path "/etc/logrotate.d/jilter"
  source 'xgemail.jilter.logrotate.erb'
  mode '0644'
  owner 'root'
  group 'root'
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
  'milter_end_of_data_macros = {i}'
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end
