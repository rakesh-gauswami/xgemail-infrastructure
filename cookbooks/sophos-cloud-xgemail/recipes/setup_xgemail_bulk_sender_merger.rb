#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_bulk_sender_merger.rb
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs a scripts that consolidates all approved bulk senders into one file
#


chef_gem 'aws-sdk' do
  action [:install]
end

require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

AWS_REGION                              = node['sophos_cloud']['region']
S3_ENCRYPTION_ALGORITHM                 = node['xgemail']['s3_encryption_algorithm']
SQS_MESSAGE_PRODUCER_TEMP_FAILURE_CODE  = node['xgemail']['temp_failure_code']
XGEMAIL_UTILS_DIR                       = node['xgemail']['xgemail_utils_files_dir']
XGEMAIL_FILES_DIR                       = node['xgemail']['xgemail_files_dir']
TEMP_FAILURE_CODE                       = node['xgemail']['temp_failure_code']

PACKAGE_DIR                     = "#{XGEMAIL_FILES_DIR}/xgemail-bulksender-service"
BULKSENDER_SCRIPT               = 'xgemail.bulksender.merger.py'
BULKSENDER_SCRIPT_PATH          = "#{PACKAGE_DIR}/#{BULKSENDER_SCRIPT}"
BULK_SENDER_PATH_PREFIX         = 'config/outbound-relay-control/bulksenders/'
MERGED_BULK_SENDER_FILENAME     = 'approved-bulksenders'


# Only continue when it's customer-submit
if NODE_TYPE != 'customer-submit'
    return
end

#directory for bulksender services
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute BULKSENDER_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write bulk sender script to customer submit instance
template BULKSENDER_SCRIPT_PATH do
  source "#{BULKSENDER_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :policy_bucket => POLICY_BUCKET_NAME,
    :bulksender_s3_path => BULK_SENDER_S3_PATH,
    :merged_bulksender_filename => MERGED_BULK_SENDER_FILENAME,
    :s3_encryption_algorithm =>  S3_ENCRYPTION_ALGORITHM,
    :temp_failure_code => TEMP_FAILURE_CODE,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
  notifies :run, "execute[#{BULKSENDER_SCRIPT_PATH}]", :immediately
end


service POLICY_POLLER_SERVICE_NAME do
  service_name POLICY_POLLER_SERVICE_NAME
  init_command "/etc/init.d/#{POLICY_POLLER_SERVICE_NAME}"
  supports :restart => true, :start => true, :stop => true, :reload => true
  subscribes :enable, 'template[xgemail-sqs-policy-poller]', :immediately
end

service POLICY_POLLER_SERVICE_NAME do
  action :start
end

