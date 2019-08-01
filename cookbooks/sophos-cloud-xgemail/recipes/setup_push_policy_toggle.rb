#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_push_policy_toggle
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures the push policy toggle script
#

NODE_TYPE           = node['xgemail']['cluster_type']
XGEMAIL_FILES_DIR   = node['xgemail']['xgemail_files_dir']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

TOGGLE_SCRIPT_NAME = "push-policy-toggle-#{NODE_TYPE}.sh"
TOGGLE_SCRIPT_PATH = "#{XGEMAIL_FILES_DIR}/push-policy-toggle"


directory TOGGLE_SCRIPT_PATH do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end


template "#{TOGGLE_SCRIPT_PATH}/#{TOGGLE_SCRIPT_NAME}" do
  source "#{TOGGLE_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
end