#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_flag_toggle_mf_outbound_submit.rb
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs creates a script which allows for the outbound split flag to be toggled
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'mf-outbound-submit'
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
