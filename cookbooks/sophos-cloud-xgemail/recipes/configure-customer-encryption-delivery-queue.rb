#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-encryption-delivery-queue
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures the postfix instance for delivery to the encryption service
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'customer-encryption'
  return
end

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

POSTFIX_INSTANCE = 'encryption-delivery';
INSTANCE_DATA = node['xgemail']['postfix_instance_data'][POSTFIX_INSTANCE]
raise "Unsupported node type [#{POSTFIX_INSTANCE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{POSTFIX_INSTANCE}]" if INSTANCE_NAME.nil?

node['xgemail']['customer_encryption_postfix_instance_name'] = POSTFIX_INSTANCE
include_recipe 'sophos-cloud-xgemail::common-postfix-multi-instance-config'

AWS_REGION = node['sophos_cloud']['region']

SOPHOS_ACCOUNT = node['sophos_cloud']['environment']

SMTP_PORT = INSTANCE_DATA[:port]

DESTINATION_PORT = 587
DESTINATION_HOST = '52.215.131.101:#{DESTINATION_PORT}'

CONFIGURATION_COMMANDS =
  [
    'relayhost=#{DESTINATION_HOST}',
    'unknown_local_recipient_reject_code=550',
    'bounce_queue_lifetime=0',
    'smtp_tls_security_level=encrypt',
    'smtp_tls_ciphers=high',
    'smtp_tls_mandatory_ciphers=high',
    'smtp_tls_loglevel=1',
    'smtp_tls_session_cache_database=btree:${data_directory}/smtp-tls-session-cache'
  ]

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end
include_recipe 'sophos-cloud-xgemail::configure-bounce-message-customer-delivery-queue'
include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_consumer'
