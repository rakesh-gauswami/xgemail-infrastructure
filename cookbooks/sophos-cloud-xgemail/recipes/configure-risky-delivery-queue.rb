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

ACCOUNT_NAME = node['sophos_cloud']['account_name']

HOP_COUNT_DELIVERY_INSTANCE = node['xgemail']['hop_count_delivery_instance']

RISKY_XDELIVERY_INSTANCE_DATA = node['xgemail']['postfix_instance_data']['risky-xdelivery']
raise "Unsupported node type [#{NODE_TYPE}]" if RISKY_XDELIVERY_INSTANCE_DATA.nil?

SMTP_PORT = RISKY_XDELIVERY_INSTANCE_DATA[:port]

if ACCOUNT_NAME == 'legacy'
  SMTP_FALLBACK_RELAY = "risky-xdelivery-cloudemail-#{AWS_REGION}.#{ACCOUNT}.hydra.sophos.com:#{SMTP_PORT}"
else
  SMTP_FALLBACK_RELAY = "risky-xdelivery.#{ACCOUNT_NAME}.ctr.sophos.com:#{SMTP_PORT}"
end

HEADER_CHECKS_PATH = "/etc/postfix-#{INSTANCE_NAME}/header_checks"

file "#{HEADER_CHECKS_PATH}" do
  content "/^X_Sophos_TLS_Connection: TLS_1_2_V$/i FILTER tls_12_verify:
/^X_Sophos_TLS_Connection: OPP_TLS_1_3$/i FILTER opps_tls_13:
/^X_Sophos_TLS_Connection: TLS_1_3$/i FILTER tls_13:
/^X_Sophos_TLS_Connection: TLS_1_3_V$/i FILTER tls_13_verify:
/^X_Sophos_TLS_Connection: PRE_TLS_1.3$/i FILTER pref_tls_13:
/^X_Sophos_TLS_Connection: PRE_TLS_1.3_V$/i FILTER pref_tls_13_verify:
/^X-Sophos-Enforce-TLS: yes$|^X-Sophos-TLS-Probe: SUCCESS$|^X_Sophos_TLS_Connection: TLS_1_2$/i FILTER smtp_encrypt:
/^X-Sophos-Email-Transport-Route: (.*)$/i FILTER $1"
  mode '0644'
  owner 'root'
  group 'root'
end

# Run an instance of the smtp process that enforces TLS encryption
[
  "tls_12_verify/unix = tls_12_verify unix - - n - - smtp -o smtp_tls_security_level=verify -o smtp_tls_mandatory_protocols=TLSv1.2 -o smtp_tls_ciphers=high -o smtp_tls_verify_cert_match=hostname,nexthop,dot-nexthop -o tls_high_cipherlist=TLSv1.2+FIPS:kRSA+FIPS:!eNULL:!aNULL",
  "opps_tls_13/unix = opps_tls_13 unix - - n - - smtp -o smtp_tls_security_level=may -o smtp_tls_protocols=TLSv1.3,TLSv1.2 -o smtp_tls_ciphers=high -o tls_high_cipherlist=TLSv1.3+FIPS:TLSv1.2+FIPS:kRSA+FIPS:!eNULL:!aNULL",
  "tls_13/unix = tls_13 unix - - n - - smtp -o smtp_tls_security_level=encrypt -o tls_high_cipherlist=TLSv1.3+FIPS:kRSA+FIPS:!eNULL:!aNULL -o smtp_tls_mandatory_protocols=TLSv1.3",
  "tls_13_verify/unix = tls_13_verify unix - - n - - smtp -o smtp_tls_security_level=verify -o tls_high_cipherlist=TLSv1.3+FIPS:kRSA+FIPS:!eNULL:!aNULL -o smtp_tls_verify_cert_match=hostname,nexthop,dot-nexthop -o smtp_tls_mandatory_protocols=TLSv1.3",
  "pref_tls_13/unix = pref_tls_13 unix - - n - - smtp -o smtp_tls_security_level=encrypt -o tls_high_cipherlist=TLSv1.2+FIPS:TLSv1.3+FIPS:kRSA+FIPS:!eNULL:!aNULL -o smtp_tls_mandatory_protocols=<=TLSv1.3",
  "pref_tls_13_verify/unix = pref_tls_13_verify unix - - n - - smtp -o smtp_tls_security_level=verify -o tls_high_cipherlist=TLSv1.2+FIPS:TLSv1.3+FIPS:kRSA+FIPS:!eNULL:!aNULL -o smtp_tls_verify_cert_match=hostname,nexthop,dot-nexthop -o smtp_tls_mandatory_protocols=<=TLSv1.3",
  "smtp_encrypt/unix = smtp_encrypt unix - - n - - smtp -o smtp_tls_mandatory_protocols=>=TLSv1.2"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -M '#{cur}'" )
end
[
  "smtp_encrypt/unix/smtp_tls_security_level=encrypt"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -P '#{cur}'" )
end

#"nested_header_checks =" is kept empty as we need to skip header checks inside attachment that is of type rfc822

if ACCOUNT != 'sandbox'
CONFIGURATION_COMMANDS =
  [
    'bounce_queue_lifetime=0',
    "hopcount_limit = #{HOP_COUNT_DELIVERY_INSTANCE}",
    "smtp_fallback_relay = #{SMTP_FALLBACK_RELAY}",
    'smtp_tls_security_level=may',
    'smtp_tls_ciphers=high',
    'smtp_tls_mandatory_ciphers=high',
    'smtp_tls_mandatory_protocols = TLSv1.2',
    'smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt',
    'smtp_tls_loglevel=1',
    'smtp_tls_session_cache_database=btree:${data_directory}/smtp-tls-session-cache',
    "header_checks = regexp:#{HEADER_CHECKS_PATH}",
    "nested_header_checks ="
  ]

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end
include_recipe 'sophos-cloud-xgemail::configure-bounce-message-risky-delivery-queue'
include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_consumer'
include_recipe 'sophos-cloud-xgemail::setup_message_history_storage_dir'
include_recipe 'sophos-cloud-xgemail::setup_message_history_files_cleanup_cron'
include_recipe 'sophos-cloud-xgemail::install_jilter_delivery'
else
  include_recipe 'sophos-cloud-xgemail::configure-bounce-message-risky-delivery-queue'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_consumer'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_utils_structure'
end
