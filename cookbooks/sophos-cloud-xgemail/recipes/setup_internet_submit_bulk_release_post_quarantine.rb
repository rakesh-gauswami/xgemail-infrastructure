#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_internet_submit_bulk_release_post_quarantine
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures the push policy toggle script on internet submit servers
#

AWS_REGION              = node['sophos_cloud']['region']
XGEMAIL_FILES_DIR       = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR       = node['xgemail']['xgemail_utils_files_dir']

PACKAGE_DIR             = "#{XGEMAIL_FILES_DIR}/bulk_release_post_quarantine"
BULK_RELEASE_SCRIPT      = 'internet-submit-bulk-release-post-quarantine.py'
INTERNET_SUBMIT_BULK_RELEASE_SCRIPT_PATH = "#{PACKAGE_DIR}/#{BULK_RELEASE_SCRIPT}"

#directory for internet submit bulk release script
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

execute INTERNET_SUBMIT_BULK_RELEASE_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write custom recipient transport script to customer delivery instance
template INTERNET_SUBMIT_BULK_RELEASE_SCRIPT_PATH do
  source "#{BULK_RELEASE_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
end

