#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: update
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
# run list for updating existing xgemail node
#

include_recipe 'sophos-cloud-snmpd::update'
include_recipe 'sophos-cloud-xgemail::configure-postfix'
