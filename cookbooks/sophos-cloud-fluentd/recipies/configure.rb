#
# Cookbook Name:: sophos-cloud-fluentd
# Recipe:: configure
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures fluentd (td-agent)
#

ACCOUNT               = node['sophos_cloud']['environment']
CONF_DIR              = node['fluentd']['conf_dir']
INSTANCE_ID           = node['ec2']['instance_id']
MAIN_DIR              = node['fluentd']['main_dir']
NODE_TYPE             = node['xgemail']['cluster_type']
PATTERNS_DIR          = node['fluentd']['patterns_dir']
REGION                = node['sophos_cloud']['region']
SNS_TOPIC             = node['xgemail']['msg_statistics_rejection_sns_topic']

# All instances - Start Order: 10
template 'fluentd-source-maillog.conf' do
  path "#{CONF_DIR}/10-source-maillog.conf"
  source 'fluentd-source-maillog.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
end

# All instances except internet-submit  - Start Order: 20
template 'fluentd-match-maillog.conf' do
  path "#{CONF_DIR}/20-match-maillog.conf"
  source 'fluentd-match-maillog.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :region => REGION
  )
  not_if { NODE_TYPE == 'submit' }
end

# All instances - Start Order: 50
template 'fluentd-filter-maillog.conf' do
  path "#{CONF_DIR}/50-filter-maillog.conf"
  source 'fluentd-filter-maillog.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :patterns_dir => PATTERNS_DIR
  )
end

# Only internet-submit  - Start Order: 60
template 'fluentd-match-msg-stats.conf' do
  path "#{CONF_DIR}/60-match-msg-stats.conf"
  source 'fluentd-match-msg-stats.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :region => REGION
  )
  only_if { NODE_TYPE == 'submit' }
end

# All instances - Start Order: 70
template 'fluentd-filter-transform.conf' do
  path "#{CONF_DIR}/70-filter-transform.conf"
  source 'fluentd-filter-transform.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :account => ACCOUNT,
    :application_name => NODE_TYPE,
    :instance_id => INSTANCE_ID,
    :region => REGION
  )
end

# All instances - Start Order: 99
template 'fluentd-match-s3.conf' do
  path "#{CONF_DIR}/99-match-s3.conf"
  source 'fluentd-match-s3.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :account => ACCOUNT,
    :region => REGION,
    :instance_id => INSTANCE_ID
  )
end

# Only internet-submit - Start Order: 99
template 'fluentd-match-sns-reject.conf' do
  path "#{CONF_DIR}/99-match-sns-reject.conf"
  source 'fluentd-match-sns-reject.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :region => REGION,
    :account => ACCOUNT,
    :sns_topic => SNS_TOPIC
  )
  only_if { NODE_TYPE == 'submit' }
end

cookbook_file 'postfix grok patterns' do
  path "#{PATTERNS_DIR}/postfix"
  source 'postfix.regexp'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'sns_reject_template' do
  path "#{MAIN_DIR}/sns_reject_template.erb"
  source 'fluentd_sns_reject_template.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

service 'td-agent' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [ :enable, :restart ]
end

