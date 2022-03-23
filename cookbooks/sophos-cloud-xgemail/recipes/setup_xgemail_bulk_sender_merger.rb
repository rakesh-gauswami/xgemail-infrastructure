#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_bulk_sender_merger.rb
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs a scripts that consolidates all approved bulk senders into one file
#


require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

# Only continue when it's customer-submit
if NODE_TYPE != 'customer-submit'
    return
end

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

AWS_REGION                              = node['sophos_cloud']['region']
S3_ENCRYPTION_ALGORITHM                 = node['xgemail']['s3_encryption_algorithm']
XGEMAIL_UTILS_DIR                       = node['xgemail']['xgemail_utils_files_dir']
XGEMAIL_FILES_DIR                       = node['xgemail']['xgemail_files_dir']
TEMP_FAILURE_CODE                       = node['xgemail']['temp_failure_code']
POLICY_BUCKET_NAME                      = node['xgemail']['xgemail_policy_bucket_name']

PACKAGE_DIR                     = "#{XGEMAIL_FILES_DIR}/xgemail-bulksender-service"
BULKSENDER_SCRIPT               = 'xgemail.bulksender.merger.py'
BULKSENDER_SCRIPT_PATH          = "#{PACKAGE_DIR}/#{BULKSENDER_SCRIPT}"
BULK_SENDER_PATH_PREFIX         = 'config/outbound-relay-control/bulksenders/'
BULK_SENDER_RESTRUCTURE_PATH    = 'outbound-relay-control/bulksenders/'
MERGED_BULK_SENDER_FILENAME     = 'approved-bulksenders'


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
    :bulksender_s3_path => BULK_SENDER_PATH_PREFIX,
    :bulksender_s3_restructure_path => BULK_SENDER_RESTRUCTURE_PATH,
    :merged_bulksender_filename => MERGED_BULK_SENDER_FILENAME,
    :s3_encryption_algorithm =>  S3_ENCRYPTION_ALGORITHM,
    :temp_failure_code => TEMP_FAILURE_CODE,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
end
