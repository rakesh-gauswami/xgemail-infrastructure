#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure_swaks
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

ACCOUNT_NAME = node['sophos_cloud']['account_name']
NODE_TYPE    = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

bash 'download_swaks' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
    echo "$(curl -O https://jetmore.org/john/code/swaks/files/swaks-20201014.0/swaks)"
  EOH
end
