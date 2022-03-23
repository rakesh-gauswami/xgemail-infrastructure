#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_flag_toggle_customer_submit.rb
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs creates a script which allows for the outbound split flag to be toggled
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'customer-submit'
  return
end

POLICY_STORAGE_PATH = node['xgemail']['policy_efs_mount_dir']
XGEMAIL_FILES_DIR = node['xgemail']['xgemail_files_dir']

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


=begin
setup script used to specify if metadata can be read from message history accepted events instead of readng policy.
=end

METADATA_FROM_MSGHISTORY_PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/metadata-from-msghistory-flag-toggle"
METADATA_FROM_MSGHISTORY_TOGGLE_SCRIPT_NAME = 'xgemail.get.metadata.from.msghistory.py'
METADATA_FROM_MSGHISTORY_TOGGLE_SCRIPT_PATH = "#{METADATA_FROM_MSGHISTORY_PACKAGE_DIR}/#{METADATA_FROM_MSGHISTORY_TOGGLE_SCRIPT_NAME}"

directory METADATA_FROM_MSGHISTORY_PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template METADATA_FROM_MSGHISTORY_TOGGLE_SCRIPT_PATH do
  source "#{METADATA_FROM_MSGHISTORY_TOGGLE_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :policy_storage_path => POLICY_STORAGE_PATH
  )
end