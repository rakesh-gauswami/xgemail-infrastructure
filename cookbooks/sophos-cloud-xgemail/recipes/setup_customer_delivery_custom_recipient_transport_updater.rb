#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_deliver_director_config_updater.rb
#
# Copyright 2020, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs a scripts that add configuration of delivery director in s3 and dynamoDb
#


require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

# Only continue when it's customer-submit
if NODE_TYPE != 'customer-delivery'
    return
end

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?


AWS_REGION              = node['sophos_cloud']['region']
ACCOUNT                 = node['sophos_cloud']['environment']

XGEMAIL_FILES_DIR          = node['xgemail']['xgemail_files_dir']
CUSTOM_TRANSPORT_FILE_NAME     = 'customer-delivery-custom-recipient-trasnport.json'
XGEMAIL_UTILS_DIR          = node['xgemail']['xgemail_utils_files_dir']

PACKAGE_DIR                            = "#{XGEMAIL_FILES_DIR}/customer-delivery-custom-transport"
CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT               = 'customer.delivery.custom-recipient-transport.updater.py'
CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT_PATH          = "#{PACKAGE_DIR}/#{CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT}"


#directory for customer delivery services
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write delivery director script to customer submit instance
template CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT_PATH do
  source "#{CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR,
    :account => ACCOUNT,
    :customer_delivery_transport_filename => CUSTOM_TRANSPORT_FILE_NAME
  )
end
