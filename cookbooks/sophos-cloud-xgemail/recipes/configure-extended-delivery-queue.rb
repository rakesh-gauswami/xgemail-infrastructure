#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-extended-delivery-queue.rb
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures an extended delivery postfix instance
#

NODE_TYPE = node['xgemail']['cluster_type']
ACCOUNT =  node['sophos_cloud']['environment']

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

MANAGED_SERVICES_IN_START_ORDER = [
  'postfix',
]

if ACCOUNT != 'sandbox'
  service 'postfix' do
    supports :restart => true, :start => true, :stop => true, :reload => true
    action :nothing
  end

  MANAGED_SERVICES_IN_START_ORDER.reverse.each do | cur |
    log "stopping service #{cur}" do
      notifies :stop, "service[#{cur}]", :immediately
    end
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
end

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

include_recipe 'sophos-cloud-xgemail::common-postfix-multi-instance-config'

[
    'bounce_queue_lifetime=0',
    'mynetworks = 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16',
    'smtp_tls_security_level=may',
    'smtp_tls_ciphers=high',
    'smtp_tls_mandatory_ciphers=high',
    'smtp_tls_loglevel=1',
    'smtp_tls_session_cache_database=btree:${data_directory}/smtp-tls-session-cache'
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end

if NODE_TYPE == 'xdelivery'
  include_recipe 'sophos-cloud-xgemail::configure-bounce-message-customer-delivery-queue'
  include_recipe 'sophos-cloud-xgemail::setup_customer_delivery_transport_updater_cron'
else
  if NODE_TYPE == 'internet-xdelivery'
    include_recipe 'sophos-cloud-xgemail::configure-bounce-message-internet-delivery-queue'
  end
end

if ACCOUNT == 'sandbox'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_utils_structure'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_processors_structure'
else
  MANAGED_SERVICES_IN_START_ORDER.each do | cur |
    log "starting service #{cur}" do
      notifies :start, "service[#{cur}]", :immediately
    end
  end
end
















