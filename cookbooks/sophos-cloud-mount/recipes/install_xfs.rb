#
# Cookbook Name:: sophos-cloud-mount
# Recipe:: install_xfs
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Install XFS
yum_package "xfsprogs" do
  action :install
end