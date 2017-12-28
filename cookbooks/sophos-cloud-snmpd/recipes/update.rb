#
# Cookbook Name:: sophos-cloud-snmpd
# Recipe:: update -- this runs after AMI deployment
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'sophos-cloud-snmpd::deploy_snmpd_conf'

service 'snmpd' do
  action :stop
end

service 'snmpd' do
  action :start
end
