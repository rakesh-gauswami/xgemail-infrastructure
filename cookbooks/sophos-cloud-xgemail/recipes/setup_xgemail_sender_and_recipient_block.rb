#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_sender_and_recipient_block.rb
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs a scripts that is used to configure block list in s3 for inbound and outbound mail flow
#


require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

# Only continue when it's customer-submit or internet-submit
if NODE_TYPE != 'customer-submit' and NODE_TYPE != 'internet-submit'
  return
end

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?


AWS_REGION              = node['sophos_cloud']['region']
ACCOUNT                 = node['sophos_cloud']['environment']

XGEMAIL_FILES_DIR       = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR       = node['xgemail']['xgemail_utils_files_dir']

SENDER_AND_RECIPIENT_BLOCK_SCRIPT      = "sender-and-recipient-block.py"
SENDER_AND_RECIPIENT_BLOCK_SCRIPT_PATH = "#{XGEMAIL_UTILS_DIR}/#{SENDER_AND_RECIPIENT_BLOCK_SCRIPT}"

#directory for block list script
directory XGEMAIL_UTILS_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute SENDER_AND_RECIPIENT_BLOCK_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write block list script to customer-submit and internet-submit
template SENDER_AND_RECIPIENT_BLOCK_SCRIPT_PATH do
  source "#{SENDER_AND_RECIPIENT_BLOCK_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :aws_region => AWS_REGION,
      :xgemail_utils_path => XGEMAIL_UTILS_DIR,
      :account => ACCOUNT
  )
end