#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_deliver_director_ioc_updater.rb
#
# Copyright 2023, Sophos
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
if NODE_TYPE != 'customer-submit' && NODE_TYPE != 'mf-outbound-submit'
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

PACKAGE_DIR                            = "#{XGEMAIL_FILES_DIR}/delivery-director-service"
DELIVERY_DIRECTOR_SCRIPT               = 'xgemail.deliverydirector.ioc.updater.py'
DELIVERY_DIRECTOR_SCRIPT_PATH          = "#{PACKAGE_DIR}/#{DELIVERY_DIRECTOR_SCRIPT}"

STATION_ACCOUNT_ROLE_ARN      = node['sophos_cloud']['station_account_role_arn']

#directory for delivery director services
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute DELIVERY_DIRECTOR_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write delivery director script to customer submit instance
template DELIVERY_DIRECTOR_SCRIPT_PATH do
  source "#{DELIVERY_DIRECTOR_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR,
    :account => ACCOUNT,
    :station_account_role_arn => STATION_ACCOUNT_ROLE_ARN
  )
end
