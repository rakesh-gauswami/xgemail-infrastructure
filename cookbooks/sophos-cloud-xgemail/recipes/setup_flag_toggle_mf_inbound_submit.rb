#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_flag_toggle_mf_inbound_submit.rb
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs creates a script which allows for the multi policy flag to be toggled
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'mf-inbound-submit'
  return
end

POLICY_STORAGE_PATH = node['xgemail']['policy_efs_mount_dir']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']


=begin
setup script used to toggle 'multi policy' toggle
=end

MULTI_POLICY_TOGGLE_PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/multi-policy-flag-toggle"
MULTI_POLICY_TOGGLE_SCRIPT_NAME = 'xgemail.multi.policy.flag.toggle.py'
MULTI_POLICY_TOGGLE_SCRIPT_PATH = "#{MULTI_POLICY_TOGGLE_PACKAGE_DIR}/#{MULTI_POLICY_TOGGLE_SCRIPT_NAME}"

directory MULTI_POLICY_TOGGLE_PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template MULTI_POLICY_TOGGLE_SCRIPT_PATH do
  source "#{MULTI_POLICY_TOGGLE_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :policy_storage_path => POLICY_STORAGE_PATH
  )
end

=begin
setup script used to toggle 'msg producer read from s3' toggle
=end

MSG_PRODUCER_READ_FROM_S3_PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/read-policy-from-s3-flag-toggle"
MSG_PRODUCER_READ_FROM_S3_TOGGLE_SCRIPT_NAME = 'xgemail.read.policy.from.s3.flag.toggle.py'
MSG_PRODUCER_READ_FROM_S3_TOGGLE_SCRIPT_PATH = "#{MSG_PRODUCER_READ_FROM_S3_PACKAGE_DIR}/#{MSG_PRODUCER_READ_FROM_S3_TOGGLE_SCRIPT_NAME}"

directory MSG_PRODUCER_READ_FROM_S3_PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template MSG_PRODUCER_READ_FROM_S3_TOGGLE_SCRIPT_PATH do
  source "#{MSG_PRODUCER_READ_FROM_S3_TOGGLE_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :policy_storage_path => POLICY_STORAGE_PATH
  )
end

=begin
setup script used to toggle 'user based split when ToC Enabled for any of the recipients' toggle
=end

TOC_USER_BASED_SPLIT_PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/toc-user-based-split-flag-toggle"
TOC_USER_BASED_SPLIT_TOGGLE_SCRIPT_NAME = 'xgemail.toc.user.based.split.flag.toggle.py'
TOC_USER_BASED_SPLIT_TOGGLE_SCRIPT_PATH = "#{TOC_USER_BASED_SPLIT_PACKAGE_DIR}/#{TOC_USER_BASED_SPLIT_TOGGLE_SCRIPT_NAME}"

directory TOC_USER_BASED_SPLIT_PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template TOC_USER_BASED_SPLIT_TOGGLE_SCRIPT_PATH do
  source "#{TOC_USER_BASED_SPLIT_TOGGLE_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :policy_storage_path => POLICY_STORAGE_PATH
  )
end

=begin
setup script used to modify which messages are split by recipient
=end

GENERAL_USER_BASED_SPLIT_PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/general-user-based-split"
GENERAL_USER_BASED_SPLIT_TOGGLE_SCRIPT_NAME = 'xgemail.user.based.split.py'
GENERAL_USER_BASED_SPLIT_TOGGLE_SCRIPT_PATH = "#{GENERAL_USER_BASED_SPLIT_PACKAGE_DIR}/#{GENERAL_USER_BASED_SPLIT_TOGGLE_SCRIPT_NAME}"

directory GENERAL_USER_BASED_SPLIT_PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template GENERAL_USER_BASED_SPLIT_TOGGLE_SCRIPT_PATH do
  source "#{GENERAL_USER_BASED_SPLIT_TOGGLE_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :policy_storage_path => POLICY_STORAGE_PATH
  )
end
