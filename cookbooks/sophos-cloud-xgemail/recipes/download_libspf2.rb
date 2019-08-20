#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: download_libspf2
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Downloads the libspf2 library but does not perform an installation
#

package 'tar'

PACKAGES_DIR = '/opt/sophos/packages'
LIBSPF2_VERSION = node['xgemail']['libspf2_version']
LIBSPF2_PACKAGE_NAME = "libspf2-#{LIBSPF2_VERSION}"

directory PACKAGES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

# Download libspf2
execute 'download_packages' do
  user 'root'
  cwd PACKAGES_DIR
  command <<-EOH
      aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['thirdparty']}/xgemail/#{LIBSPF2_PACKAGE_NAME}.tar.gz .
  EOH
end