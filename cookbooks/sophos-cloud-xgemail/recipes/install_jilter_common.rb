#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_common
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Common setup for both inbound and outbound jilter servers
#

DEPLOYMENT_DIR = node['xgemail']['xgemail_files_dir']
PACKAGES_DIR = '/opt/sophos/packages'

LIBSPF2_VERSION = node['xgemail']['libspf2_version']
LIBSPF2_PACKAGE_NAME = "libspf2-#{LIBSPF2_VERSION}"

directory DEPLOYMENT_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end


# Extract libspf2 files, these were downloaded to the AMI by the download_libspf2 recipe
execute 'extract libspf2 files' do
  user 'root'
  cwd PACKAGES_DIR
  command <<-EOH
    tar xzf #{LIBSPF2_PACKAGE_NAME}.tar.gz
  EOH
end


# Install libspf2
rpm_package 'install libspf2' do
  action :install
  package_name "#{LIBSPF2_PACKAGE_NAME}.el6.x86_64.rpm"
  source "#{PACKAGES_DIR}/#{LIBSPF2_PACKAGE_NAME}.el6.x86_64.rpm"
end