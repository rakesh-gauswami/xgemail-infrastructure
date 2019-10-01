#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-risky-delivery-queue
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures risky delivery postfix instance
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'risky-delivery'
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

HOP_COUNT_DELIVERY_INSTANCE = node['xgemail']['hop_count_delivery_instance']

RISKY_XDELIVERY_INSTANCE_DATA = node['xgemail']['postfix_instance_data']['risky-xdelivery']
raise "Unsupported node type [#{NODE_TYPE}]" if RISKY_XDELIVERY_INSTANCE_DATA.nil?

SMTP_PORT = RISKY_XDELIVERY_INSTANCE_DATA[:port]

SMTP_FALLBACK_RELAY = "risky-xdelivery-cloudemail-#{AWS_REGION}.#{ACCOUNT}.hydra.sophos.com:#{SMTP_PORT}"

HEADER_CHECKS_PATH = "/etc/postfix-#{INSTANCE_NAME}/header_checks"

file "#{HEADER_CHECKS_PATH}" do
  content "/^X-Sophos-Enforce-TLS: yes$|^X-Sophos-TLS-Probe: SUCCESS$/i FILTER smtp_encrypt:"
  mode '0644'
  owner 'root'
  group 'root'
end

# Run an instance of the smtp process that enforces TLS encryption
[
  "smtp_encrypt/unix = smtp_encrypt unix - - n - - smtp"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -M '#{cur}'" )
end
[
  "smtp_encrypt/unix/smtp_tls_security_level=encrypt"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -P '#{cur}'" )
end

if ACCOUNT != 'sandbox'
CONFIGURATION_COMMANDS =
  [
    'bounce_queue_lifetime=0',
    "hopcount_limit = #{HOP_COUNT_DELIVERY_INSTANCE}",
    "smtp_fallback_relay = #{SMTP_FALLBACK_RELAY}",
    'smtp_tls_security_level=may',
    'smtp_tls_ciphers=high',
    'smtp_tls_mandatory_ciphers=high',
    'smtp_tls_loglevel=1',
    'smtp_tls_session_cache_database=btree:${data_directory}/smtp-tls-session-cache',
    "header_checks = regexp:#{HEADER_CHECKS_PATH}"
  ]

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end
include_recipe 'sophos-cloud-xgemail::configure-bounce-message-risky-delivery-queue'
include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_consumer'
else
  include_recipe 'sophos-cloud-xgemail::configure-bounce-message-risky-delivery-queue'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_consumer'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_utils_structure'
end
