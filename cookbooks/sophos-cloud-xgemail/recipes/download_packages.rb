#
# Cookbook Name:: sophos-cloud-xgemail 
# Recipe:: download_packages
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Constants
# Cyren
CTASD_PACKAGE_VERSION = "#{node['xgemail']['ctasd_package_version']}"
CTASD_PACKAGE_NAME = "ctasd-#{CTASD_PACKAGE_VERSION}"
# SAVi
SAVI_PACKAGE_VERSION = "#{node['xgemail']['savdid_savi_version']}"
SAVI_PACKAGE_NAME = "savi-#{SAVI_PACKAGE_VERSION}"
# SAV-DI
SAVDI_PACKAGE_VERSION = "#{node['xgemail']['savdid_version']}"
SAVDI_PACKAGE_NAME = "savdi-#{SAVDI_PACKAGE_VERSION}"

directory '/opt/sophos/packages' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

execute 'download_packages' do
  user 'root'
  cwd '/opt/sophos/packages'
  command <<-EOH
      aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['thirdparty']}/xgemail/#{CTASD_PACKAGE_NAME}.tar.gz .
      aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['thirdparty']}/xgemail/#{SAVI_PACKAGE_NAME}.tar.gz .
      aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['thirdparty']}/xgemail/#{SAVDI_PACKAGE_NAME}.tar.gz .
  EOH
end