#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-internet-delivery-queue
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures internet delivery postfix instance
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'internet-delivery'
  return
end

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

include_recipe 'sophos-cloud-xgemail::common-postfix-multi-instance-config'

AWS_REGION = node['sophos_cloud']['region']

ACCOUNT = node['sophos_cloud']['environment']

INTERNET_XDELIVERY_INSTANCE_DATA = node['xgemail']['postfix_instance_data']['internet-xdelivery']
raise "Unsupported node type [#{NODE_TYPE}]" if INTERNET_XDELIVERY_INSTANCE_DATA.nil?

SMTP_PORT = INTERNET_XDELIVERY_INSTANCE_DATA[:port]

SMTP_FALLBACK_RELAY = "internet-xdelivery-cloudemail-#{AWS_REGION}.#{ACCOUNT}.hydra.sophos.com:#{SMTP_PORT}"

if ACCOUNT != 'sandbox'
CONFIGURATION_COMMANDS =
  [
    'bounce_queue_lifetime=0',
    "smtp_fallback_relay = #{SMTP_FALLBACK_RELAY}",
    'smtp_tls_security_level=may',
    'smtp_tls_ciphers=high',
    'smtp_tls_mandatory_ciphers=high',
    'smtp_tls_loglevel=1',
    'smtp_tls_session_cache_database=btree:${data_directory}/smtp-tls-session-cache'
  ]

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end
include_recipe 'sophos-cloud-xgemail::configure-bounce-message-internet-delivery-queue'
include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_consumer'
else
  include_recipe 'sophos-cloud-xgemail::configure-bounce-message-internet-delivery-queue'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_consumer'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_utils_structure'
end