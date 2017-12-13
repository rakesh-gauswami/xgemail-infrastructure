#
# Cookbook Name:: sophos-cloud-snmpd
# Recipe:: configure-ubuntu
# Package name is different on ubuntu and is automatically added to run level 3
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Configure snmpd

package "snmp"
package "snmpd"

include_recipe "sophos-cloud-snmpd::deploy_snmpd_conf_ubuntu"

service "snmpd" do
  action :restart
end
