#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_gem_aws_sdk
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#

chef_gem "aws-sdk" do

  version '2.11.393'
end