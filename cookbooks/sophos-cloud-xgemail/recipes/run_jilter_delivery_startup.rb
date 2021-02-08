#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: run_jilter_delivery_startup
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# configure and run jilter-delivery-startup script to start jilter on startup based on s3 flag

NODE_TYPE     = node['xgemail']['cluster_type']
INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

XGEMAIL_FILES_DIR    = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR    = node['xgemail']['xgemail_utils_files_dir']
XGEMAIL_CONFIG_DIR   = "#{XGEMAIL_FILES_DIR}/config"
AWS_REGION           = node['sophos_cloud']['region']
POLICY_BUCKET_NAME   = node['xgemail']['xgemail_policy_bucket_name']

DELIVERY_JILTER_ENABLED_S3_PATH   = node['xgemail']['delivery_jilter_enabled_s3_path']

DELIVERY_JILTER_ENABLED_FILE_PATH = "#{XGEMAIL_CONFIG_DIR}/delivery.jilter.enabled"
STARTUP_SCRIPT_PATH = "#{XGEMAIL_FILES_DIR}/startup"

directory STARTUP_SCRIPT_PATH do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template "#{STARTUP_SCRIPT_PATH}/jilter-delivery-startup.sh" do
  source "jilter-delivery-startup.sh.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :instance_name => INSTANCE_NAME,
    :policy_bucket => POLICY_BUCKET_NAME,
    :delivery_jilter_enabled_file_path => DELIVERY_JILTER_ENABLED_FILE_PATH,
    :delivery_jilter_enabled_s3_path => DELIVERY_JILTER_ENABLED_S3_PATH,
    :xgemail_utils_dir => XGEMAIL_UTILS_DIR
  )
end

# Run jilter-delivery-startup.sh
execute 'jilter-delivery-startup' do
  command "sh #{STARTUP_SCRIPT_PATH}/jilter-delivery-startup.sh"
end

