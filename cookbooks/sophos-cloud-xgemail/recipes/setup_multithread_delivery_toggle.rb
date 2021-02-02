#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_multithread_delivery_toggle
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configure the delivery multithread toggle script in all frontline delivery servers (excluding x-delivery servers)
#

XGEMAIL_FILES_DIR   = node['xgemail']['xgemail_files_dir']

XGEMAIL_CONFIG_DIR = "#{XGEMAIL_FILES_DIR}/config"
AWS_REGION         = node['sophos_cloud']['region']
POLICY_BUCKET_NAME = node['xgemail']['xgemail_policy_bucket_name']
DELIVERY_MULTITHREAD_ENABLED_FILE_PATH = node['xgemail']['delivery_multithread_enabled_file_path']
DELIVERY_MULTITHREAD_ENABLED_S3_PATH = node['xgemail']['delivery_multithread_enabled_s3_path']

TOGGLE_SCRIPT_PATH = "#{XGEMAIL_FILES_DIR}/multithread-delivery-toggle"

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

template "#{TOGGLE_SCRIPT_PATH}/multithread-delivery-toggle.sh" do
  source "multithread-delivery-toggle.sh.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :delivery_multithread_enabled_file_path => DELIVERY_MULTITHREAD_ENABLED_FILE_PATH,
    :delivery_multithread_enabled_s3_path => DELIVERY_MULTITHREAD_ENABLED_S3_PATH,
    :policy_bucket => POLICY_BUCKET_NAME
  )
end
