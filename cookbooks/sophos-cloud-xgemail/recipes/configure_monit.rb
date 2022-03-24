#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure_monit
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

ACCOUNT_NAME = node['sophos_cloud']['account_name']
NODE_TYPE    = node['xgemail']['cluster_type']

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
  only_if {
    ACCOUNT_NAME == 'legacy'
  }
end

template '/etc/monit.d/postfix.conf' do
  source 'monit-postfix-fsc.conf.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables(
    :instance_name => INSTANCE_NAME
  )
  not_if {
    ACCOUNT_NAME != 'legacy'
  }
end

template '/etc/monit.d/submit.conf' do
  source 'monit-submit.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'internet-submit' || NODE_TYPE == 'mf-inbound-submit' }
end

template '/etc/monit.d/customer-submit.conf' do
  source 'monit-customer-submit.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'customer-submit' || NODE_TYPE == 'mf-outbound-submit' }
end

template '/etc/monit.d/delivery.conf' do
  source 'monit-delivery.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'mf-inbound-delivery' || NODE_TYPE == 'internet-delivery' || NODE_TYPE == 'mf-outbound-delivery' || NODE_TYPE == 'encryption-delivery' || NODE_TYPE == 'risky-delivery' || NODE_TYPE == 'warmup-delivery' || NODE_TYPE == 'beta-delivery' || NODE_TYPE == 'delta-delivery' }
end

template '/etc/monit.d/xdelivery.conf' do
  source 'monit-xdelivery.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'xdelivery' || NODE_TYPE == 'customer-xdelivery' || NODE_TYPE == 'internet-xdelivery' || NODE_TYPE == 'risky-xdelivery' || NODE_TYPE == 'warmup-xdelivery' || NODE_TYPE == 'beta-xdelivery' || NODE_TYPE == 'delta-xdelivery' || NODE_TYPE == 'mf-inbound-xdelivery' || NODE_TYPE == 'mf-outbound-xdelivery'}
end

template '/etc/monit.d/transport-updater.conf' do
  source 'monit-transport-updater.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'xdelivery' || NODE_TYPE == 'customer-xdelivery' || NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'mf-inbound-xdelivery'}
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
