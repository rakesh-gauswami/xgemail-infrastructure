#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_customer_delivery_custom_recipient_transport_updater
#
# Copyright 2021, Sophos
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

# Only continue when it's customer-delivery or mf-inbound-delivery
if NODE_TYPE != 'customer-delivery' && NODE_TYPE != 'mf-inbound-delivery'
    return
end

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?


AWS_REGION              = node['sophos_cloud']['region']
ACCOUNT                 = node['sophos_cloud']['environment']

XGEMAIL_FILES_DIR               = node['xgemail']['xgemail_files_dir']
CUSTOM_ROUTE_TRANSPORT_PATH     = node['xgemail']['custom_route_transport_path']
XGEMAIL_UTILS_DIR               = node['xgemail']['xgemail_utils_files_dir']
POLICY_BUCKET                   = node['xgemail']['xgemail_policy_bucket_name']

PACKAGE_DIR                                     = "#{XGEMAIL_FILES_DIR}/customer-delivery-custom-transport"
CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT      = 'custom.recipient.transport.updater.py'
CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT_PATH = "#{PACKAGE_DIR}/#{CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT}"


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

# Write custom recipient transport script to customer delivery instance
template CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT_PATH do
  source "#{CUSTOMER_DIRECTORY_CUSTOM_TRANSPORT_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR,
    :account => ACCOUNT,
    :policy_bucket => POLICY_BUCKET,
    :custom_route_transport_path => CUSTOM_ROUTE_TRANSPORT_PATH
  )
end
