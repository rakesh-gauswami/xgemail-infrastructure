#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_inbound
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure Xgemail Jilter service for inbound email processing
#

package 'tar'

NODE_TYPE = node['xgemail']['cluster_type']

# Make sure we're on an internet submit node
if NODE_TYPE != 'submit'
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
JILTER_VERSION = node['xgemail']['jilter_inbound_version']
JILTER_PACKAGE_PREFIX = 'xgemail-jilter-inbound'
JILTER_PACKAGE_NAME = "#{JILTER_PACKAGE_PREFIX}-#{JILTER_VERSION}"
JILTER_SCRIPT_DIR = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/scripts"
JILTER_SCRIPT_PATH = "#{JILTER_SCRIPT_DIR}/xgemail.jilter.service.sh"

LIBOPENDKIM_VERSION = node['xgemail']['libopendkim_version']
LIBOPENDKIM_PACKAGE_NAME = "libopendkim-#{LIBOPENDKIM_VERSION}"

SERVICE_USER = node['xgemail']['jilter_user']

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
file "/etc/rsyslog.d/00-#{JILTER_PACKAGE_PREFIX}.conf" do
  content "if $syslogtag == '[#{JILTER_PACKAGE_PREFIX}]' and $syslogseverity <= '6' then /var/log/xgemail/jilter.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end


# Add fluentd config file to monitor log file and submit to S3 for Logz.io.
template '/etc/td-agent.d/20-source-jilter.conf' do
  source 'fluentd-source-jilter.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
      :application_name => NODE_TYPE
  )
end


# Restart syslog
service 'rsyslog' do
  action :restart
end


# Extract the jilter package to /opt/sophos/xgemail/JILTER_PACKAGE_NAME
# This was downloaded from S3 while building the AMI
execute 'extract_jilter_package' do
  user 'root'
  cwd PACKAGES_DIR
  command <<-EOH
      tar xf #{JILTER_PACKAGE_NAME}.tar -C #{DEPLOYMENT_DIR}
  EOH
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
      yum-config-manager --enable epel
      yum install -y #{LIBOPENDKIM_PACKAGE_NAME}
      yum-config-manager --disable epel
  EOH
end


# dkim jni movement
src = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/lib/libdkimjni-#{LIBDKIM_JNI_VERSION}.so"

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

# Cleanup the deployment package
file "#{PACKAGES_DIR}/#{JILTER_PACKAGE_NAME}.tar" do
  action :delete
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

# Create jilter user
user SERVICE_USER do
  system true
  shell '/sbin/nologin'
end

# Create the Jilter service
template 'xgemail.jilter.service.sh' do
  path JILTER_SCRIPT_PATH
  source 'xgemail.jilter.inbound.service.sh.erb'
  mode '0700'
  owner SERVICE_USER
  group SERVICE_USER
  variables(
      :jilter_version => JILTER_VERSION,
      :deployment_dir => DEPLOYMENT_DIR
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
    'milter_connect_macros = {client_addr}, {j}'
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end