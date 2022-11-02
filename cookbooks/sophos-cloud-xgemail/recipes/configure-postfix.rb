#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-postfix
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures default postfix instance and delegates worker instance configuration
# to specific queue configuration recipe
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

ACCOUNT = node['sophos_cloud']['environment']
FILE_CACHE_DIR = ::Chef::Config[:file_cache_path]

CONFIGURATION_COMMANDS =
  node['xgemail']['common_instance_config_params'] +
  [
    # Disable inet services for default instance
    'master_service_disable = inet'
  ]

CONFIGURATION_COMMANDS_SANDBOX =
    node['xgemail']['common_instance_config_params'] +
    [
        # Disable inet services for default instance
        'master_service_disable = inet'
    ]

SQS_MESSAGE_CONSUMER_SERVICE_NAME = node['xgemail']['sqs_message_consumer_service_name']


service 'postfix' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action :stop
end

if ACCOUNT != 'sandbox'
  JILTER_SERVICE_NAME = node['xgemail']['jilter_service_name']

  # First configure default instance
  CONFIGURATION_COMMANDS.each do | cur |
    execute "postconf '#{cur}'"
  end

else
  # First configure default instance
  CONFIGURATION_COMMANDS_SANDBOX.each do | cur |
    execute "postconf -e '#{cur}'"
  end
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

include_recipe 'sophos-cloud-xgemail::setup_iptables_nat_rules'
include_recipe 'sophos-cloud-xgemail::configure-internet-submit-queue'
include_recipe 'sophos-cloud-xgemail::configure-customer-submit-queue'
include_recipe 'sophos-cloud-xgemail::configure-customer-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-internet-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-encryption-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-encryption-submit-queue'
include_recipe 'sophos-cloud-xgemail::configure-risky-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-warmup-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-beta-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-delta-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-mf-inbound-submit-queue'
include_recipe 'sophos-cloud-xgemail::configure-mf-outbound-submit-queue'
include_recipe 'sophos-cloud-xgemail::configure-mf-outbound-delivery-queue'
include_recipe 'sophos-cloud-xgemail::configure-mf-inbound-delivery-queue'
include_recipe 'sophos-cloud-xgemail::setup-postfix-qstat-cron'

if ACCOUNT == 'sandbox'
  include_recipe 'sophos-cloud-xgemail::configure-extended-delivery-queue'
end

MANAGED_SERVICES_IN_START_ORDER =
  [
    'postfix'
  ]

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'internet-delivery' || NODE_TYPE == 'encryption-delivery' || NODE_TYPE == 'risky-delivery' || NODE_TYPE == 'warmup-delivery' || NODE_TYPE == 'beta-delivery' || NODE_TYPE == 'delta-delivery' || NODE_TYPE == 'mf-inbound-delivery' || NODE_TYPE == 'mf-outbound-delivery'
  MANAGED_SERVICES_IN_START_ORDER = [
  'postfix'
]
else
  if NODE_TYPE == 'internet-submit' || NODE_TYPE == 'customer-submit' || NODE_TYPE == 'encryption-submit' || NODE_TYPE == 'mf-inbound-submit' || NODE_TYPE == 'mf-outbound-submit'
    if ACCOUNT != 'sandbox'
       MANAGED_SERVICES_IN_START_ORDER = [
          JILTER_SERVICE_NAME,
          'postfix'
      ]
    else
      MANAGED_SERVICES_IN_START_ORDER = [
          'postfix'
      ]
    end
  end
end

if NODE_TYPE == 'xdelivery' || NODE_TYPE == 'customer-xdelivery' || NODE_TYPE == 'mf-inbound-xdelivery'
  MANAGED_SERVICES_IN_START_ORDER = [
      'postfix'
  ]
end

MANAGED_SERVICES_IN_START_ORDER.each do | cur |
  log "starting service #{cur}" do
    notifies :start, "service[#{cur}]", :immediately
  end
end
