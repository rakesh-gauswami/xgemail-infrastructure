#
# Cookbook Name:: sophos-base-ami
# Recipe:: base_ami
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# run list for instantiating packages required for all AMIs
#

include_recipe 'sophos-central-diag::install'
include_recipe 'sophos-central-python::common'
include_recipe 'sophos-cloud-common::install_chef_gem_aws_sdk'
include_recipe 'sophos-cloud-common::install_debugging_tools'
include_recipe 'sophos-cloud-common::disable_auto_update'
include_recipe 'sophos-cloud-common::configure_auditd'
