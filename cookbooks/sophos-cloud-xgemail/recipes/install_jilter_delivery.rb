#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_delivery
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure Xgemail Jilter service for delivery servers
#

package 'tar'

NODE_TYPE = node['xgemail']['cluster_type']
ACCOUNT = node['sophos_cloud']['account']

# Make sure we're on an delivery node
unless NODE_TYPE == 'customer-delivery' or NODE_TYPE == 'internet-delivery' or
  NODE_TYPE == 'xdelivery' or NODE_TYPE == 'internet-xdelivery' or
  NODE_TYPE == 'encryption-delivery' or NODE_TYPE == 'risky-delivery' or
  NODE_TYPE == 'risky-xdelivery' or NODE_TYPE == 'warmup-delivery' or
  NODE_TYPE == 'warmup-xdelivery' or NODE_TYPE == 'beta-delivery' or
  NODE_TYPE == 'beta-xdelivery' or NODE_TYPE == 'delta-delivery' or
  NODE_TYPE == 'delta-xdelivery'
  return
end

# convert the node-type to NODE_TYPE to make it compatible with ServerType in Java code
server_type_map = {
  'customer-delivery'   => 'CUSTOMER_DELIVERY',
  'xdelivery'           => 'CUSTOMER_XDELIVERY',
  'internet-delivery'   => 'INTERNET_DELIVERY',
  'internet-xdelivery'  => 'INTERNET_XDELIVERY',
  'risky-delivery'      => 'RISKY_DELIVERY',
  'risky-xdelivery'     => 'RISKY_XDELIVERY',
  'warmup-delivery'     => 'WARMUP_DELIVERY',
  'warmup-xdelivery'    => 'WARMUP_XDELIVERY',
  'beta-delivery'       => 'BETA_DELIVERY',
  'beta-xdelivery'      => 'BETA_XDELIVERY'
  'delta-delivery'      => 'DELTA_DELIVERY',
  'delta-xdelivery'     => 'DELTA_XDELIVERY',
  'encryption-delivery' => 'ENCRYPTION_DELIVERY'
}

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

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
AWS_REGION = node['sophos_cloud']['region']
SERVICE_USER = node['xgemail']['jilter_user']
POLICY_BUCKET_NAME   = node['xgemail']['xgemail_policy_bucket_name']
ACTIVE_PROFILE = node['xgemail']['xgemail_active_profile']

CUSTOMER_SUBMIT_BUCKET_NAME = node['xgemail']['xgemail_bucket_name']

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
      :policy_bucket => POLICY_BUCKET_NAME,
      :account => ACCOUNT,
      :customer_submit_bucket => CUSTOMER_SUBMIT_BUCKET_NAME,
      :aws_region => AWS_REGION,
      :server_type => server_type_map[NODE_TYPE],
      :server_ip => SERVER_IP,
      :mh_mail_info_storage_dir => MH_MAIL_INFO_STORAGE_DIR,
      :msg_history_dynamodb_table_name =>  MSG_HISTORY_DYNAMODB_TABLE_NAME
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

# # disable jilter by default; will enable jilter by a toggle script
# [
#   'smtpd_milters = inet:localhost:9876',
#   'milter_connect_macros = {client_addr}, {j}',
#   'milter_end_of_data_macros = {i}'
# ].each do | cur |
#   execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
# end
