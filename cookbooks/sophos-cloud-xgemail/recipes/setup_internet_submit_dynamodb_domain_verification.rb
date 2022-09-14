#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_internet_submit_dynamodb_domain_verification
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe compare legacy Domain and recipient with DynamoDB entry
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

ACCOUNT               = node['sophos_cloud']['context']
ACCOUNT_NAME          = node['sophos_cloud']['account_name']
REGION                = node['sophos_cloud']['region']
STATION_VPC_NAME      = node['xgemail']['station_vpc_name']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']
RELAY_DOMAINS_FILENAME  = node['xgemail']['relay_domains_filename']
RECIPIENT_ACCESS_FILENAME = node['xgemail']['recipient_access_filename']
XGEMAIL_UTILS_DIR       = node['xgemail']['xgemail_utils_files_dir']
STATION_ACCOUNT_ROLE_ARN      = node['sophos_cloud']['station_account_role_arn']

PACKAGE_DIR                    = "#{XGEMAIL_FILES_DIR}/toggle-flat-file"
DYNAMODB_SCRIPT                = 'internet.submit.dynamodb.domain.mailbox.verify.py'
DYNAMODB_SCRIPT_PATH           = "#{PACKAGE_DIR}/#{DYNAMODB_SCRIPT}"


#directory for flat file
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute DYNAMODB_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write submit script to compare domain and recipient in dynamodb
template DYNAMODB_SCRIPT_PATH do
  source "#{DYNAMODB_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :postfix_instance_name => instance_name( INSTANCE_NAME ),
    :relay_domains_filename => RELAY_DOMAINS_FILENAME,
    :recipient_access_filename => RECIPIENT_ACCESS_FILENAME,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR,
    :station_account_role_arn => STATION_ACCOUNT_ROLE_ARN,
    :aws_region => REGION,
    :account => ACCOUNT
  )
end
