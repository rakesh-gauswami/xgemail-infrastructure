#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure_monit
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

template '/etc/monit.d/postfix.conf' do
    source 'monit-postfix.conf.erb'
    mode '0755'
    owner 'root'
    group 'root'
    variables(
            :instance_name => INSTANCE_NAME
    )
end

template '/etc/monit.d/submit.conf' do
  source 'monit-submit.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'internet-submit' }
end

template '/etc/monit.d/customer-submit.conf' do
  source 'monit-customer-submit.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'customer-submit' }
end

template '/etc/monit.d/delivery.conf' do
  source 'monit-delivery.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'internet-delivery' || NODE_TYPE == 'encryption-delivery' || NODE_TYPE == 'risky-delivery' || NODE_TYPE == 'warmup-delivery' || NODE_TYPE == 'delta-delivery' }
end

# Restart rsyslog service
service 'rsyslog' do
    action :restart
end

# Restart td-agent service
service 'td-agent' do
    action :restart
end

# Add and start Monit service
service 'monit' do
    action :enable
end