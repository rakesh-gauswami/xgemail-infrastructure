#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_internet_submit_flat_file_flag
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs a scripts that set configuration of flat file for internet submit instace based on flag
#

require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

# Only continue when it's internet-submit or mf-inbound-submit
if NODE_TYPE != 'internet-submit' && NODE_TYPE != 'mf-inbound-submit'
    return
end

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

AWS_REGION              = node['sophos_cloud']['region']
ACCOUNT                 = node['sophos_cloud']['environment']

XGEMAIL_FILES_DIR               = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR               = node['xgemail']['xgemail_utils_files_dir']
POLICY_BUCKET                   = node['xgemail']['xgemail_policy_bucket_name']
INSTANCE_ID                     = node['ec2']['instance_id']

PACKAGE_DIR                     = "#{XGEMAIL_FILES_DIR}/toggle-flat-file"
TOGGLE_FLAT_FILE_SCRIPT      = 'flat.file.enable.internet.submit.py'
TOGGLE_FLAT_FILE_SCRIPT_PATH = "#{PACKAGE_DIR}/#{TOGGLE_FLAT_FILE_SCRIPT}"

#directory for customer delivery services
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute TOGGLE_FLAT_FILE_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write toggle flat file enable script to customer delivery instance
template TOGGLE_FLAT_FILE_SCRIPT_PATH do
  source "#{TOGGLE_FLAT_FILE_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :instance_id => INSTANCE_ID,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR,
    :account => ACCOUNT,
    :postfix_instance_name => instance_name( INSTANCE_NAME ),
    :policy_bucket => POLICY_BUCKET
  )
end