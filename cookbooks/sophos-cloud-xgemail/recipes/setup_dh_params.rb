#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_db_params
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure cron job for updating dh parameters
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

# setup_xgemail_utils_structure creates this directory
XGEMAIL_FILES_DIR = node['xgemail']['xgemail_files_dir']

PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/dh-params-cron"
CRON_SCRIPT = 'update-dh-params.bash'
CRON_SCRIPT_PATH = "#{PACKAGE_DIR}/#{CRON_SCRIPT}"

directory PACKAGE_DIR do
  mode "0755"
  owner "root"
  group "root"
end

# Prepare cron script execution
execute CRON_SCRIPT_PATH do
  user "root"
  action :nothing
end

template CRON_SCRIPT_PATH do
  source "#{CRON_SCRIPT}.erb"
  mode "0750"
  owner "root"
  group "root"
  variables(
    :postfix_instance_name => instance_name( INSTANCE_NAME )
  )
  notifies :run, "execute[#{CRON_SCRIPT_PATH}]", :immediately
end

# Update dh parameters twice a day
cron CRON_SCRIPT_PATH do
  minute "9"
  hour "2,14"
  user "root"
  command "source /etc/profile && '#{CRON_SCRIPT_PATH}' >/dev/null 2>&1"
end


[
  'smtpd_tls_dh512_param_file = $config_directory/dh512.pem',

  # See http://www.postfix.org/postconf.5.html#smtpd_tls_dh1024_param_file about
  # why dh2048 is used here
  'smtpd_tls_dh1024_param_file = $config_directory/dh2048.pem'
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end
