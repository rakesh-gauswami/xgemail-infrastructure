#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_inbound
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure Xgemail Jilter service for inbound email processing
#

PACKAGES_DIR = '/jilter'
DEPLOYMENT_DIR = '/opt/sophos/xgemail'

NODE_TYPE = node['xgemail']['cluster_type']
DIRECTION = node['xgemail']['direction']
JILTER_VERSION = node['xgemail']['jilter_version']

JILTER_PACKAGE_NAME = "xgemail-jilter-#{DIRECTION}-#{JILTER_VERSION}"


directory PACKAGES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory DEPLOYMENT_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

execute 'extract_jilter_package' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      tar xf #{JILTER_PACKAGE_NAME}.tar -C #{DEPLOYMENT_DIR}
  EOH
end

# Create a sym link to xgemail-jilter
link "#{DEPLOYMENT_DIR}/xgemail-jilter-#{DIRECTION}" do
  to "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}"
end
