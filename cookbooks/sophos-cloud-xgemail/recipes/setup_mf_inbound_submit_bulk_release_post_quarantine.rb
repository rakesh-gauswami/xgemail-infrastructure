#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: mf-inbound-submit-bulk-release-post-quarantine
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures the post quarantine bulk release script on internet submit servers
#

require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

AWS_REGION              = node['sophos_cloud']['region']
XGEMAIL_FILES_DIR       = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR       = node['xgemail']['xgemail_utils_files_dir']

PACKAGE_DIR             = "#{XGEMAIL_FILES_DIR}/bulk_release_post_quarantine"
BULK_RELEASE_SCRIPT      = 'mf-inbound-submit-bulk-release-post-quarantine.py'
MF_INBOUND_SUBMIT_BULK_RELEASE_SCRIPT_PATH = "#{PACKAGE_DIR}/#{BULK_RELEASE_SCRIPT}"

#directory for mf inbound submit bulk release script
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute MF_INBOUND_SUBMIT_BULK_RELEASE_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write bulk release script to internet submit instance
template MF_INBOUND_SUBMIT_BULK_RELEASE_SCRIPT_PATH do
  source "#{BULK_RELEASE_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
end

