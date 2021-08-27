#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_mf_inbound_routing_managers.rb
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configures routing manager CLI tools
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'mf-inbound-submit'
  return
end


POLICY_STORAGE_PATH              = node['xgemail']['policy_efs_mount_dir']
XGEMAIL_FILES_DIR                = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR                = node['xgemail']['xgemail_utils_files_dir']
ROUTING_MANAGERS_CLI_PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/routing-managers-cli"

# Internet submit routing manager CLI
MF_INBOUND_SUBMIT_MANAGER_SCRIPT_NAME = 'xgemail.mf.inbound.submit.service.routing.cli.py'
MF_INBOUND_SUBMIT_MANAGER_SCRIPT_PATH = "#{ROUTING_MANAGERS_CLI_PACKAGE_DIR}/#{MF_INBOUND_SUBMIT_MANAGER_SCRIPT_NAME}"


directory ROUTING_MANAGERS_CLI_PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end


template MF_INBOUND_SUBMIT_MANAGER_SCRIPT_PATH do
  source "#{MF_INBOUND_SUBMIT_MANAGER_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :policy_storage_path => POLICY_STORAGE_PATH,
      :xgemail_utils_path => XGEMAIL_UTILS_DIR,
  )
end