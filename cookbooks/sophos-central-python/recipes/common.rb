#
# Cookbook Name:: sophos-central-python
# Recipe:: common
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Include Helper library
::Chef::Recipe.send(
  :include,
  ::SophosCloud::CommonHelper
)
::Chef::Resource.send(
  :include,
  ::SophosCloud::CommonHelper
)

COMMON_PACKAGE = 'common'

PYTHON_COMMON_PACKAGE_DIR = "#{common_cookbook_install_dir}/#{COMMON_PACKAGE}"
PACKAGE_INSTALLER_NAME = 'install_package.py'
PACKAGE_INSTALLER_FILE = "#{common_cookbook_install_dir}/#{PACKAGE_INSTALLER_NAME}"

# Create cookbook directories recursively
directory common_cookbook_install_dir do
  mode  '0755'
  recursive true
end

# Useful packages from pip.
node["pip3"].each_key do |package|
  python_package package do
    version = node["pip3"][package]["version"]
  end
end

remote_directory PYTHON_COMMON_PACKAGE_DIR do
  source COMMON_PACKAGE
  files_mode '0644'
  purge true
end

cookbook_file PACKAGE_INSTALLER_FILE do
  source PACKAGE_INSTALLER_NAME
  mode "0755"
end

# Our own packages.
execute "'#{PACKAGE_INSTALLER_FILE}' '#{PYTHON_COMMON_PACKAGE_DIR}'"
