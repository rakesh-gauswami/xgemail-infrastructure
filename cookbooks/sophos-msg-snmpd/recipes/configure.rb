#
# Cookbook Name:: sophos-msg-snmpd
# Recipe:: configure -- this runs during AMI deployment
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Configure snmpd

package 'net-snmp'

include_recipe 'sophos-msg-snmpd::deploy_snmpd_conf'

service 'snmpd' do
  action :start
end

bash 'add_snmpd_to_startup' do
  user 'root'
  code <<-EOH
    chkconfig --level 3 snmpd on
  EOH
end
