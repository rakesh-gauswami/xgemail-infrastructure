#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_iptables_nat_rules
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#
# Create Post Routing NAT rules in IPTABLES to load balance outbound traffic from each of the attached EIPs
#
# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']
IP_LIST = node['ec2']['local_ipv4']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

#iptables -t nat -A POSTROUTING -o eth0 -p tcp -m statistic --mode random --probability 0.3 -j SNAT --to-source $IP




# Restart iptables service
service 'iptables' do
  action :restart
end
