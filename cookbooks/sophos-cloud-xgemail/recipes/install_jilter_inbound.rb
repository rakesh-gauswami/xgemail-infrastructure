#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_inbound
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure Xgemail Jilter service for inbound email processing
#

package 'tar'
AWS_REGION = node['sophos_cloud']['region']
CENTRAL_VPC_ID = node['xgemail']['station_vpc_id']

NODE_TYPE = node['xgemail']['cluster_type']
ACCOUNT = node['sophos_cloud']['environment']

# Make sure we're on an internet submit node
if NODE_TYPE != 'internet-submit' && NODE_TYPE != 'jilter-inbound'
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
JILTER_PACKAGE_NAME = 'xgemail-jilter-inbound'
JILTER_SCRIPT_DIR = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/scripts"
JILTER_SCRIPT_PATH = "#{JILTER_SCRIPT_DIR}/xgemail.jilter.service.sh"
JILTER_CONF_DIR = "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}/conf"
JILTER_APPLICATION_PROPERTIES_PATH="#{JILTER_CONF_DIR}/jilter-application.properties"
JILTER_HELO_TELEMETRY_STREAM_NAME = node['xgemail']['jilter_helo_telemetry_stream_name']

LIBOPENDKIM_VERSION = node['xgemail']['libopendkim_version']
LIBOPENDKIM_PACKAGE_NAME = "libopendkim-#{LIBOPENDKIM_VERSION}"

SERVICE_USER = node['xgemail']['jilter_user']
POLICY_BUCKET_NAME   = node['xgemail']['xgemail_policy_bucket_name']
ACTIVE_PROFILE = node['xgemail']['xgemail_active_profile']

INTERNET_SUBMIT_BUCKET_NAME = node['xgemail']['xgemail_bucket_name']

if ACCOUNT == 'sandbox'
  include_recipe 'sophos-cloud-xgemail::install_jilter_code_sandbox'
  include_recipe 'sophos-cloud-xgemail::install_jilter_common'
else
  include_recipe 'sophos-cloud-xgemail::install_jilter_common'
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

# Give ownership to the jilter service user
file "#{JILTER_CONF_DIR}/launch_darkly_#{ACCOUNT}.properties" do
  owner SERVICE_USER
  group SERVICE_USER
  action :touch
end


# Create the jilter application properties
template 'xgemail.jilter.properties' do
  path JILTER_APPLICATION_PROPERTIES_PATH
  source 'jilter-inbound-application.properties.erb'
  mode '0700'
  owner SERVICE_USER
  group SERVICE_USER
  variables(
      :aws_region => AWS_REGION,
      :central_vpc_id => CENTRAL_VPC_ID,
      :policy_bucket => POLICY_BUCKET_NAME,
      :account => ACCOUNT,
      :internet_submit_bucket => INTERNET_SUBMIT_BUCKET_NAME,
      :jilter_helo_telemetry_stream => JILTER_HELO_TELEMETRY_STREAM_NAME
  )
end

if ACCOUNT != 'sandbox'

  # Create the Jilter service
  template 'xgemail.jilter.service.sh' do
    path JILTER_SCRIPT_PATH
    source 'xgemail.jilter.inbound.service.sh.erb'
    mode '0700'
    owner SERVICE_USER
    group SERVICE_USER
    variables(
        :deployment_dir => DEPLOYMENT_DIR,
        :property_path => JILTER_APPLICATION_PROPERTIES_PATH,
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
      'milter_mail_macros = {mail_addr}, {tls_version}',
      'milter_helo_macros = {client_ptr}',
      'milter_end_of_data_macros = {i}'
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end

else

  APPLICATION = node['xgemail']['application']
  DIRECTION   = node['xgemail']['direction']

  template "launch_darkly_sandbox.properties" do
    path "#{DEPLOYMENT_DIR}/xgemail-jilter-#{DIRECTION}/conf/launch_darkly_sandbox.properties"
    source 'jilter-launch-darkly.properties.erb'
    mode '0700'
    variables(
        :launch_darkly_key => node['xgemail']['launch_darkly_sandbox']
    )
  end

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
