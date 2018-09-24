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

if NODE_TYPE != 'customer-encryption-delivery'
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

SOPHOS_ACCOUNT = node['sophos_cloud']['environment']

ENCRYPTION_XDELIVERY_INSTANCE_DATA = node['xgemail']['postfix_instance_data']['encryption-xdelivery']
raise "Unsupported node type [#{NODE_TYPE}]" if ENCRYPTION_XDELIVERY_INSTANCE_DATA.nil?

SMTP_PORT = ENCRYPTION_XDELIVERY_INSTANCE_DATA[:port]

SMTP_FALLBACK_RELAY = "encryption-xdelivery-cloudemail-#{AWS_REGION}.#{SOPHOS_ACCOUNT}.hydra.sophos.com:#{SMTP_PORT}"

CONFIGURATION_COMMANDS =
  [
    # This is a host on the Echoworx side, we don't have it now, will be updated
    #'relayhost'=[???echoworx.com]:587',

    'queue_directory=/storage/postfix-cd',
    'command_directory=/usr/sbin',
    'daemon_directory=/usr/libexec/postfix',
    'data_directory=/var/lib/postfix-cd',
    'mail_owner=postfix',
    'unknown_local_recipient_reject_code=550',
    'bounce_queue_lifetime=0',
    'smtp_fallback_relay=#{SMTP_FALLBACK_RELAY}',
    'smtp_tls_security_level=encrypt',
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
