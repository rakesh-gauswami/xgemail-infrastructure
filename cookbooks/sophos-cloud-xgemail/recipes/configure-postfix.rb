#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-postfix
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures default postfix instance and delegates worker instance configuration
# to specific queue configuration recipe
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

FILE_CACHE_DIR = ::Chef::Config[:file_cache_path]

CONFIGURATION_COMMANDS =
  node['xgemail']['common_instance_config_params'] +
  [
    # Disable inet services for default instance
    'master_service_disable = inet'
  ]

SQS_MESSAGE_CONSUMER_SERVICE_NAME = node['xgemail']['sqs_message_consumer_service_name']
JILTER_SERVICE_NAME = node['xgemail']['jilter_service_name']

service 'postfix' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action :stop
end

# First configure default instance
CONFIGURATION_COMMANDS.each do | cur |
  execute "postconf '#{cur}'"
end

# Enable multi-instance support
# Create new instance
POSTMULTI_INIT_GUARD = ::File.join( FILE_CACHE_DIR, ".postfix-postmulti-init" )
execute "#{print_postmulti_init()} && touch #{POSTMULTI_INIT_GUARD}" do
  creates POSTMULTI_INIT_GUARD
end

ruby_block 'cleanup_config_files' do
  block do
    cleanup_main_cf POSTMULTI_DEFAULT_INSTANCE
    cleanup_master_cf POSTMULTI_DEFAULT_INSTANCE
  end
end

include_recipe 'sophos-cloud-xgemail::configure-internet-submit-queue'
include_recipe 'sophos-cloud-xgemail::configure-customer-submit-queue'
include_recipe 'sophos-cloud-xgemail::configure-customer-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-internet-delivery-queue'

MANAGED_SERVICES_IN_START_ORDER =
  [
    'postfix'
  ]

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE == 'delivery' || NODE_TYPE == 'internet-delivery'
  MANAGED_SERVICES_IN_START_ORDER = [
  'postfix',
  SQS_MESSAGE_CONSUMER_SERVICE_NAME
]
end

if NODE_TYPE == 'submit' || NODE_TYPE == 'customer-submit'
  MANAGED_SERVICES_IN_START_ORDER = [
      JILTER_SERVICE_NAME,
      'postfix'
  ]
end

MANAGED_SERVICES_IN_START_ORDER.each do | cur |
  log "starting service #{cur}" do
    notifies :start, "service[#{cur}]", :immediately
  end
end
