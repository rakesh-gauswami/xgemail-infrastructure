#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-extended-delivery-queue.rb
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures an extended delivery postfix instance
#

NODE_TYPE = node['xgemail']['cluster_type']
ACCOUNT =  node['sophos_cloud']['environment']

if NODE_TYPE != 'xdelivery' && NODE_TYPE != 'customer-xdelivery' && NODE_TYPE != 'internet-xdelivery' && NODE_TYPE != 'risky-xdelivery' && NODE_TYPE != 'warmup-xdelivery' && NODE_TYPE != 'beta-xdelivery' && NODE_TYPE != 'delta-xdelivery' && NODE_TYPE != 'mf-inbound-xdelivery' && NODE_TYPE != 'mf-outbound-xdelivery'
  return
end

LOCAL_CERT_PATH = node['sophos_cloud']['local_cert_path']
LOCAL_KEY_PATH = node['sophos_cloud']['local_key_path']

CERT_NAME = node['xgemail']['cert']

CERT_FILE = "#{LOCAL_CERT_PATH}/#{CERT_NAME}.crt"
KEY_FILE = "#{LOCAL_KEY_PATH}/#{CERT_NAME}.key"
SERVER_PEM_FILE = "#{LOCAL_CERT_PATH}/server.pem"

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

FILE_CACHE_DIR = ::Chef::Config[:file_cache_path]

CONFIGURATION_COMMANDS =
  node['xgemail']['common_instance_config_params'] +
  [
    # Disable inet services for default instance
    'master_service_disable = inet',
    'inet_protocols = ipv4'
  ]

MANAGED_SERVICES_IN_START_ORDER = [
  'postfix',
]

if ACCOUNT != 'sandbox'
  GLOBAL_SIGN_DIR = "#{LOCAL_CERT_PATH}/3rdparty/global-sign"
  GLOBAL_SIGN_INTERMEDIARY = "#{GLOBAL_SIGN_DIR}/global-sign-sha256-intermediary.crt"
  GLOBAL_SIGN_CROSSCERT = "#{LOCAL_CERT_PATH}/globalsign-cross-certificate.crt"
  GLOBAL_SIGN_ROOT = "#{LOCAL_CERT_PATH}/globalsign-rsa-ca.crt"

  # Add xgemail certificate
  remote_file "/etc/ssl/certs/#{CERT_NAME}.crt" do
    source "file:///tmp/sophos/certificates/api-mcs-mob-prod.crt"
    owner 'root'
    group 'root'
    mode 0444
  end

  remote_file "/etc/ssl/certs/globalsign-cross-certificate.crt" do
    source "file:///tmp/sophos/certificates/globalsign-cross-certificate.crt"
    owner 'root'
    group 'root'
    mode 0444
  end

  remote_file "/etc/ssl/certs/globalsign-rsa-ca.crt" do
    source "file:///tmp/sophos/certificates/globalsign-rsa-ca.crt"
    owner 'root'
    group 'root'
    mode 0444
  end

  # Add xgemail key
  remote_file "/etc/ssl/private/#{CERT_NAME}.key" do
    source "file:///tmp/sophos/certificates/appserver.key"
    owner 'root'
    group 'root'
    mode 0440
  end

  CREATE_SERVER_PEM_COMMAND = 'cat ' +
    "'#{CERT_FILE}' " +
    "'#{GLOBAL_SIGN_CROSSCERT}' " +
    "'#{GLOBAL_SIGN_ROOT}' " +
    "> '#{SERVER_PEM_FILE}'"

  file SERVER_PEM_FILE do
    owner 'root'
    group 'root'
    mode '0444'
    action :create
  end

  execute CREATE_SERVER_PEM_COMMAND

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

HOP_COUNT_DELIVERY_INSTANCE = node['xgemail']['hop_count_delivery_instance']

include_recipe 'sophos-cloud-xgemail::common-postfix-multi-instance-config'

# Run an instance of the smtp process that enforces TLS encryption
[
  "tls_12_verify/unix = tls_12_verify unix - - n - - smtp -o smtp_tls_security_level=verify -o smtp_tls_mandatory_protocols=TLSv1.2 -o smtp_tls_ciphers=high -o smtp_tls_verify_cert_match=hostname,nexthop,dot-nexthop -o tls_high_cipherlist=TLSv1.2+FIPS:kRSA+FIPS:!eNULL:!aNULL",
  "opps_tls_13/unix = opps_tls_13 unix - - n - - smtp -o smtp_tls_security_level=may -o smtp_tls_protocols=TLSv1.3,TLSv1.2 -o smtp_tls_ciphers=high -o tls_high_cipherlist=TLSv1.3+FIPS:TLSv1.2+FIPS:kRSA+FIPS:!eNULL:!aNULL",
  "tls_13/unix = tls_13 unix - - n - - smtp -o smtp_tls_security_level=encrypt -o tls_high_cipherlist=TLSv1.3+FIPS:kRSA+FIPS:!eNULL:!aNULL -o smtp_tls_mandatory_protocols=TLSv1.3",
  "tls_13_verify/unix = tls_13_verify unix - - n - - smtp -o smtp_tls_security_level=verify -o tls_high_cipherlist=TLSv1.3+FIPS:kRSA+FIPS:!eNULL:!aNULL -o smtp_tls_verify_cert_match=hostname,nexthop,dot-nexthop -o smtp_tls_mandatory_protocols=TLSv1.3",
  "pref_tls_13/unix = pref_tls_13 unix - - n - - smtp -o smtp_tls_security_level=encrypt -o tls_high_cipherlist=TLSv1.3+FIPS:kRSA+FIPS:!eNULL:!aNULL -o smtp_tls_mandatory_protocols=<=TLSv1.3",
  "pref_tls_13_verify/unix = pref_tls_13_verify unix - - n - - smtp -o smtp_tls_security_level=verify -o tls_high_cipherlist=TLSv1.3+FIPS:kRSA+FIPS:!eNULL:!aNULL -o smtp_tls_verify_cert_match=hostname,nexthop,dot-nexthop -o smtp_tls_mandatory_protocols=<=TLSv1.3",
  "smtp_encrypt/unix = smtp_encrypt unix - - n - - smtp"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -M '#{cur}'" )
end



[
  "smtp_encrypt/unix/smtp_tls_security_level=encrypt"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -P '#{cur}'" )
end

if NODE_TYPE == 'mf-inbound-xdelivery' || NODE_TYPE == 'mf-outbound-xdelivery'
  [
      # Server side TLS configuration
      'smtpd_tls_security_level = may',
      'smtpd_tls_ciphers = high',
      'smtpd_tls_mandatory_ciphers = high',
      'smtpd_tls_loglevel = 1',
      'smtpd_tls_received_header = yes',
      "smtpd_tls_cert_file = #{SERVER_PEM_FILE}",
      "smtpd_tls_key_file = #{KEY_FILE}",
      'bounce_queue_lifetime=0',
      "hopcount_limit = #{HOP_COUNT_DELIVERY_INSTANCE}",
      'mynetworks = 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16',
      'smtp_tls_security_level = encrypt',
      'smtp_tls_ciphers=high',
      'smtp_tls_mandatory_ciphers = high',
      'smtp_tls_mandatory_protocols = !SSLv2,!SSLv3,!TLSv1,!TLSv1.1,TLSv1.2',
      'smtp_tls_protocols = !SSLv2,!SSLv3,!TLSv1,!TLSv1.1,TLSv1.2',
      'smtp_tls_loglevel=1',
      'smtp_tls_session_cache_database=btree:${data_directory}/smtp-tls-session-cache',
      'soft_bounce=yes'
  ].each do |cur|
    execute print_postmulti_cmd(INSTANCE_NAME, "postconf '#{cur}'")
  end
else
  [
      # Server side TLS configuration
      'smtpd_tls_security_level = may',
      'smtpd_tls_ciphers = high',
      'smtpd_tls_mandatory_ciphers = high',
      'smtpd_tls_loglevel = 1',
      'smtpd_tls_received_header = yes',
      "smtpd_tls_cert_file = #{SERVER_PEM_FILE}",
      "smtpd_tls_key_file = #{KEY_FILE}",
      'bounce_queue_lifetime=0',
      "hopcount_limit = #{HOP_COUNT_DELIVERY_INSTANCE}",
      'mynetworks = 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16',
      'smtp_tls_security_level=may',
      'smtp_tls_ciphers=high',
      'smtp_tls_mandatory_ciphers=high',
      'smtp_tls_mandatory_protocols = TLSv1.2',
      'smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt',
      'smtp_tls_loglevel=1',
      'smtp_tls_session_cache_database=btree:${data_directory}/smtp-tls-session-cache'
  ].each do |cur|
    execute print_postmulti_cmd(INSTANCE_NAME, "postconf '#{cur}'")
  end
end


if NODE_TYPE == 'internet-xdelivery' || NODE_TYPE == 'risky-xdelivery' || NODE_TYPE == 'warmup-xdelivery' || NODE_TYPE == 'beta-xdelivery' || NODE_TYPE == 'delta-xdelivery'

  HEADER_CHECKS_PATH = "/etc/postfix-#{INSTANCE_NAME}/header_checks"

  file "#{HEADER_CHECKS_PATH}" do
    content "/^X_Sophos_TLS_Connection: TLS_1_2_V$/i FILTER tls_12_verify:
/^X_Sophos_TLS_Connection: OPP_TLS_1_3$/i FILTER opps_tls_13:
/^X_Sophos_TLS_Connection: TLS_1_3$/i FILTER tls_13:
/^X_Sophos_TLS_Connection: TLS_1_3_V$/i FILTER tls_13_verify:
/^X_Sophos_TLS_Connection: PRE_TLS_1.3$/i FILTER pref_tls_13:
/^X_Sophos_TLS_Connection: PRE_TLS_1.3_V$/i FILTER pref_tls_13_verify:
/^X-Sophos-Enforce-TLS: yes$|^X-Sophos-TLS-Probe: SUCCESS$|^X_Sophos_TLS_Connection: TLS_1_2$/i FILTER smtp_encrypt:"
    mode '0644'
    owner 'root'
    group 'root'
  end

  [
    "header_checks = regexp:#{HEADER_CHECKS_PATH}"
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end
end

if NODE_TYPE == 'mf-outbound-xdelivery'

  HEADER_CHECKS_PATH = "/etc/postfix-#{INSTANCE_NAME}/header_checks"

  file "#{HEADER_CHECKS_PATH}" do
    content "/^X-Sophos-Enforce-TLS: yes$|^X-Sophos-TLS-Probe: SUCCESS$/i FILTER smtp_encrypt:"
    mode '0644'
    owner 'root'
    group 'root'
  end

  [
    "header_checks = regexp:#{HEADER_CHECKS_PATH}"
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end
end

if NODE_TYPE == 'xdelivery' || NODE_TYPE == 'customer-xdelivery'

  TRANSPORT_ROUTE_HEADER_CHECKS_PATH = "/etc/postfix-#{INSTANCE_NAME}/header_checks"

  # Add the header checks config file
  file "#{TRANSPORT_ROUTE_HEADER_CHECKS_PATH}" do
    content "/^X-Sophos-Email-Transport-Route: (smtp|smtp_encrypt):(.*)$/i FILTER $1:$2"
    mode '0644'
    owner 'root'
    group 'root'
  end

  include_recipe 'sophos-cloud-xgemail::configure-bounce-message-customer-delivery-queue'
  include_recipe 'sophos-cloud-xgemail::setup_customer_delivery_transport_updater'
  include_recipe 'sophos-cloud-xgemail::setup_flat_file_rollout_config'
  include_recipe 'sophos-cloud-xgemail::setup_customer_delivery_transport_updater_cron'
  include_recipe 'sophos-cloud-xgemail::setup_push_policy_delivery_toggle'
else
  if NODE_TYPE == 'internet-xdelivery'
    include_recipe 'sophos-cloud-xgemail::configure-bounce-message-internet-delivery-queue'
  end
  if NODE_TYPE == 'risky-xdelivery'
    include_recipe 'sophos-cloud-xgemail::configure-bounce-message-risky-delivery-queue'
  end
  if NODE_TYPE == 'warmup-xdelivery'
    include_recipe 'sophos-cloud-xgemail::configure-bounce-message-warmup-delivery-queue'
  end
  if NODE_TYPE == 'beta-xdelivery'
    include_recipe 'sophos-cloud-xgemail::configure-bounce-message-beta-delivery-queue'
  end
  if NODE_TYPE == 'delta-xdelivery'
    include_recipe 'sophos-cloud-xgemail::configure-bounce-message-delta-delivery-queue'
  end
  if NODE_TYPE == 'mf-inbound-xdelivery'

    TRANSPORT_ROUTE_HEADER_CHECKS_PATH = "/etc/postfix-#{INSTANCE_NAME}/header_checks"

    # Add the header checks config file
    file "#{TRANSPORT_ROUTE_HEADER_CHECKS_PATH}" do
      content "/^X-Sophos-Email-Transport-Route: (smtp|smtp_encrypt):(.*)$/i FILTER $1:$2"
      mode '0644'
      owner 'root'
      group 'root'
    end
    include_recipe 'sophos-cloud-xgemail::configure-bounce-message-customer-delivery-queue'
    include_recipe 'sophos-cloud-xgemail::setup_mf_inbound_delivery_transport_updater_cron'
    include_recipe 'sophos-cloud-xgemail::setup_flat_file_rollout_config'
    include_recipe 'sophos-cloud-xgemail::setup_customer_delivery_transport_updater_cron'
    include_recipe 'sophos-cloud-xgemail::setup_push_policy_delivery_toggle'
  end
  if NODE_TYPE == 'mf-outbound-xdelivery'
    include_recipe 'sophos-cloud-xgemail::configure-bounce-message-mf-outbound-delivery-queue'
    include_recipe 'sophos-cloud-xgemail::setup_mf_outbound_delivery_relay_by_sender_updater_cron'
  end
end

# Setup multi IP NAT rules in IPTABLES if IP_COUNT > 1 for all xdelivery types
include_recipe 'sophos-cloud-xgemail::setup_iptables_nat_rules'

# Setup postfix qstat cron on all Xdelivery servers to report postfix queue metrics
include_recipe 'sophos-cloud-xgemail::setup-postfix-qstat-cron'

# recipes to be run in all x-delivery servers for Mhv2
include_recipe 'sophos-cloud-xgemail::setup_message_history_storage_dir'
include_recipe 'sophos-cloud-xgemail::setup_message_history_files_cleanup_cron'
include_recipe 'sophos-cloud-xgemail::install_jilter_delivery'
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
