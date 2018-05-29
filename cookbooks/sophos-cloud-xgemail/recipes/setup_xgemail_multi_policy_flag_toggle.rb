#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_multi_policy_flag_toggle.rb
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs creates a script which allows for the multi policy flag to be toggled
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'submit'
  return
end

POLICY_STORAGE_PATH = node['xgemail']['policy_efs_mount_dir']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']

PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/multi-policy-flag-toggle"
TOGGLE_SCRIPT_NAME = 'xgemail.multi.policy.flag.toggle.py'
TOGGLE_SCRIPT_PATH = "#{PACKAGE_DIR}/#{TOGGLE_SCRIPT_NAME}"

directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template TOGGLE_SCRIPT_PATH do
  source "#{TOGGLE_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :policy_storage_path => POLICY_STORAGE_PATH
  )
end
