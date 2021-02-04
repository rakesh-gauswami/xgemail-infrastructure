#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: run_multithread_delivery_startup
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#

# configure and run multithread-delivery-startup script to enable mulithreading in sqs consumer on startup based on s3 flag

XGEMAIL_FILES_DIR    = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR    = node['xgemail']['xgemail_utils_files_dir']
POLICY_BUCKET_NAME   = node['xgemail']['xgemail_policy_bucket_name']
AWS_REGION           = node['sophos_cloud']['region']
DELIVERY_MULTITHREAD_ENABLED_FILE_PATH = node['xgemail']['delivery_multithread_enabled_file_path']
DELIVERY_MULTITHREAD_ENABLED_S3_PATH   = node['xgemail']['delivery_multithread_enabled_s3_path']

STARTUP_SCRIPT_PATH = "#{XGEMAIL_FILES_DIR}/startup"

directory STARTUP_SCRIPT_PATH do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template "#{STARTUP_SCRIPT_PATH}/multithread-delivery-startup.sh" do
  source "multithread-delivery-startup.sh.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :policy_bucket => POLICY_BUCKET_NAME,
    :delivery_multithread_enabled_s3_path => DELIVERY_MULTITHREAD_ENABLED_S3_PATH,
    :delivery_multithread_enabled_file_path => DELIVERY_MULTITHREAD_ENABLED_FILE_PATH,
    :xgemail_utils_dir => XGEMAIL_UTILS_DIR
  )
end

# Run multithread-delivery-startup.sh
execute 'multithread-delivery-startup' do
  command "sh #{STARTUP_SCRIPT_PATH}/multithread-delivery-startup.sh"
end
