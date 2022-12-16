#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-mf-outbound-delivery-queue
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures internet delivery postfix instance
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'mf-outbound-delivery'
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

ACCOUNT_NAME = node['sophos_cloud']['account_name']

HOP_COUNT_DELIVERY_INSTANCE = node['xgemail']['hop_count_delivery_instance']

MF_OUTBOUND_XDELIVERY_INSTANCE_DATA = node['xgemail']['postfix_instance_data']['mf-outbound-xdelivery']
raise "Unsupported node type [#{NODE_TYPE}]" if MF_OUTBOUND_XDELIVERY_INSTANCE_DATA.nil?

SMTP_PORT = MF_OUTBOUND_XDELIVERY_INSTANCE_DATA[:port]

if ACCOUNT_NAME == 'legacy'
  SMTP_FALLBACK_RELAY = "mf-outbound-xdelivery-cloudemail-#{AWS_REGION}.#{ACCOUNT}.hydra.sophos.com:#{SMTP_PORT}"
else
  SMTP_FALLBACK_RELAY = "mf-outbound-xdelivery.#{ACCOUNT_NAME}.ctr.sophos.com:#{SMTP_PORT}"
end

HEADER_CHECKS_PATH = "/etc/postfix-#{INSTANCE_NAME}/header_checks"

file "#{HEADER_CHECKS_PATH}" do
  content "/^X-Sophos-Email-Transport-Route: (smtp|smtp_encrypt):(.*)$/i FILTER $1:$2"
  mode '0644'
  owner 'root'
  group 'root'
end

# Run an instance of the smtp process that enforces TLS encryption
[
  "smtp_encrypt/unix = smtp_encrypt unix - - n - - smtp -o smtp_tls_mandatory_protocols=>=TLSv1.2"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -M '#{cur}'" )
end
[
  "smtp_encrypt/unix/smtp_tls_security_level=encrypt"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -P '#{cur}'" )
end

CONFIGURATION_COMMANDS =
  [
    'soft_bounce=yes',
    'bounce_queue_lifetime=0',
    "hopcount_limit = #{HOP_COUNT_DELIVERY_INSTANCE}",
    "smtp_fallback_relay = #{SMTP_FALLBACK_RELAY}",
    'smtp_tls_security_level = encrypt',
    'smtp_tls_ciphers=high',
    'smtp_tls_mandatory_ciphers = high',
    'smtp_tls_mandatory_protocols = !SSLv2,!SSLv3,!TLSv1,!TLSv1.1,TLSv1.2',
    'smtp_tls_protocols = !SSLv2,!SSLv3,!TLSv1,!TLSv1.1,TLSv1.2',
    'smtp_tls_loglevel=1',
    'smtp_tls_session_cache_database=btree:${data_directory}/smtp-tls-session-cache'
  ]

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end

if ACCOUNT == 'sandbox'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_mf_outbound_utils_structure'
end

include_recipe 'sophos-cloud-xgemail::setup_mf_outbound_delivery_relay_by_sender_updater_cron'
include_recipe 'sophos-cloud-xgemail::configure-bounce-message-mf-outbound-delivery-queue'
include_recipe 'sophos-cloud-xgemail::setup_transport_route_config'
include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_consumer'
include_recipe 'sophos-cloud-xgemail::setup_message_history_storage_dir'
include_recipe 'sophos-cloud-xgemail::setup_message_history_files_cleanup_cron'
include_recipe 'sophos-cloud-xgemail::install_jilter_delivery'
include_recipe 'sophos-cloud-xgemail::setup_push_policy_delivery_toggle'