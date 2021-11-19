#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_transport_route_config
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configures the transport route config CLI tool

NODE_TYPE           = node['xgemail']['cluster_type']
XGEMAIL_FILES_DIR   = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR   = node['xgemail']['xgemail_utils_files_dir']


TRANSPORT_ROUTE_CLI_PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/transport-route-config-cli"
TRANSPORT_ROUTE_CLI_SCRIPT_NAME = 'xgemail.transport.route.config.cli.py'
TRANSPORT_ROUTE_CLI_SCRIPT_PATH = "#{TRANSPORT_ROUTE_CLI_PACKAGE_DIR}/#{TRANSPORT_ROUTE_CLI_SCRIPT_NAME}"

TRANSPORT_CONFIG_DIR = XGEMAIL_FILES_DIR + '/config'
TRANSPORT_CONFIG_FILE_NAME = "#{TRANSPORT_CONFIG_DIR}/transport-route-config.json"

if NODE_TYPE != 'customer-delivery' && NODE_TYPE != 'mf-inbound-delivery'
  return
end


directory TRANSPORT_ROUTE_CLI_PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end


directory TRANSPORT_CONFIG_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end


template TRANSPORT_ROUTE_CLI_SCRIPT_PATH do
  source "#{TRANSPORT_ROUTE_CLI_SCRIPT_NAME}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
      :xgemail_utils_path => XGEMAIL_UTILS_DIR,
      :transport_config_path => TRANSPORT_CONFIG_FILE_NAME
  )
end