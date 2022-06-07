#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_flat_file_initial_sync_transport
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures the Script for initial sync of transport on customer delivery servers
#

require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

AWS_REGION              = node['sophos_cloud']['region']
XGEMAIL_FILES_DIR       = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR       = node['xgemail']['xgemail_utils_files_dir']

PACKAGE_DIR             = "#{XGEMAIL_FILES_DIR}/toggle-flat-file"
INITIAL_SYNC_TRANSPORT_SCRIPT      = 'flat.file.initial.sync.transport.py'
INITIAL_SYNC_TRANSPORT_SCRIPT_PATH = "#{PACKAGE_DIR}/#{INITIAL_SYNC_TRANSPORT_SCRIPT}"

#directory for internet submit bulk release script
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute INITIAL_SYNC_TRANSPORT_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write initial sync script to customer delivery and mf inbound delivery instance
template INITIAL_SYNC_TRANSPORT_SCRIPT_PATH do
  source "#{INITIAL_SYNC_TRANSPORT_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
end

