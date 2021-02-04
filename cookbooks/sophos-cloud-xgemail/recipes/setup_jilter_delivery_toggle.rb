#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_jilter_delivery_toggle
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configure the toggle jilter script in all delivery servers
#

NODE_TYPE           = node['xgemail']['cluster_type']
XGEMAIL_FILES_DIR   = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR   = node['xgemail']['xgemail_utils_files_dir']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

XGEMAIL_CONFIG_DIR = "#{XGEMAIL_FILES_DIR}/config"
AWS_REGION         = node['sophos_cloud']['region']
POLICY_BUCKET_NAME = node['xgemail']['xgemail_policy_bucket_name']
DELIVERY_JILTER_ENABLED_S3_PATH = node['xgemail']['delivery_jilter_enabled_s3_path']

TOGGLE_SCRIPT_PATH = "#{XGEMAIL_FILES_DIR}/jilter-delivery-toggle"

directory XGEMAIL_CONFIG_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory TOGGLE_SCRIPT_PATH do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template "#{TOGGLE_SCRIPT_PATH}/jilter-delivery-toggle.sh" do
  source "jilter-delivery-toggle.sh.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :delivery_jilter_enabled_s3_path => DELIVERY_JILTER_ENABLED_S3_PATH,
    :instance_name => INSTANCE_NAME,
    :policy_bucket => POLICY_BUCKET_NAME,
    :xgemail_utils_dir => XGEMAIL_UTILS_DIR
  )
end
