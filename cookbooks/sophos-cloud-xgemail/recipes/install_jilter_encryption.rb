#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_encryption
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure Xgemail Jilter service for receiving encrypted emails
#

package 'tar'

NODE_TYPE = node['xgemail']['cluster_type']
ACCOUNT = node['sophos_cloud']['account']

# Make sure we're on an encryption submit node
if NODE_TYPE != 'encryption-submit'
  return
end

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

DEPLOYMENT_DIR = node['xgemail']['xgemail_files_dir']
PACKAGES_DIR = '/opt/sophos/packages'

JILTER_SERVICE_NAME = node['xgemail']['jilter_service_name']
JILTER_PACKAGE_NAME = 'xgemail-jilter-encryption'
JILTER_SCRIPT_DIR = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/scripts"
JILTER_SCRIPT_PATH = "#{JILTER_SCRIPT_DIR}/xgemail.jilter.service.sh"

SERVICE_USER = node['xgemail']['jilter_user']
ACTIVE_PROFILE = node['xgemail']['xgemail_active_profile']

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

# Create jilter user
user SERVICE_USER do
  system true
  shell '/sbin/nologin'
end

# Create the Jilter service
template 'xgemail.jilter.service.sh' do
  path JILTER_SCRIPT_PATH
  source 'xgemail.jilter.encryption.service.sh.erb'
  mode '0700'
  owner SERVICE_USER
  group SERVICE_USER
  variables(
    :active_profile => ACTIVE_PROFILE
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
  'milter_end_of_data_macros = {i}'
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end
