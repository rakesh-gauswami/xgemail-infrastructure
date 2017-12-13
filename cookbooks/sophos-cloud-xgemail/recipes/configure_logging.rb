#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-logging
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures default postfix instance and delegates worker instance configuration
# to specific queue configuraiton recipe
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE             = node['xgemail']['cluster_type']
ACCOUNT               = node['sophos_cloud']['environment']
REGION                = node['sophos_cloud']['region']
INSTANCE_ID           = node['ec2']['instance_id']

template 'fluentd-source-maillog.conf' do
  path '/etc/td-agent.d/10-source-maillog.conf'
  source 'fluentd-source-maillog.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :region => REGION
  )
  not_if { NODE_TYPE == 'elasticsearch' }
end

template 'fluentd-source-elasticsearch.conf' do
  path '/etc/td-agent.d/00-source-elasticsearch.conf'
  source 'fluentd-source-elasticsearch.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :region => REGION,
    :account => ACCOUNT
  )
  only_if { NODE_TYPE == 'elasticsearch' }
end

template 'fluentd-filter-transform.conf' do
  path '/etc/td-agent.d/75-filter-transform.conf'
  source 'fluentd-filter-transform.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :region => REGION,
    :account => ACCOUNT
  )
end

template 'fluentd-match-s3.conf' do
  path '/etc/td-agent.d/99-match-s3.conf'
  source 'fluentd-match-s3.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :region => REGION,
    :account => ACCOUNT,
    :instance_id => INSTANCE_ID
  )
end

service 'td-agent' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [ :enable, :restart ]
end

