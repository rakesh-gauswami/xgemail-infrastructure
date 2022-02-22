#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-internet-submit-queue
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures internet submit postfix instance
#

ACCOUNT =   node['sophos_cloud']['environment']
NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'internet-submit'
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

LOCAL_CERT_PATH = node['sophos_cloud']['local_cert_path']
LOCAL_KEY_PATH = node['sophos_cloud']['local_key_path']

CERT_NAME = node['xgemail']['cert']

CERT_FILE = "#{LOCAL_CERT_PATH}/#{CERT_NAME}.crt"
KEY_FILE = "#{LOCAL_KEY_PATH}/#{CERT_NAME}.key"

RECIPIENT_ACCESS_FILENAME = node['xgemail']['recipient_access_filename']
RECIPIENT_ACCESS_EXTRA_FILENAME = node['xgemail']['recipient_access_extra_filename']
SOFT_RETRY_SENDERS_MAP_FILENAME = node['xgemail']['soft_retry_senders_map_filename']

SERVER_PEM_FILE = "#{LOCAL_CERT_PATH}/server.pem"

WELCOME_MSG_SENDER = node['xgemail']['welcome_msg_sender']

# mainly used for forwarding VBSpam messages to Sophos Labs
RECIPIENT_BCC_MAPS_FILE = 'recipient_bcc_maps'
RECIPIENT_BCC_MAPS_PATH = "/etc/postfix-#{INSTANCE_NAME}/#{RECIPIENT_BCC_MAPS_FILE}"
TRANSPORT_MAPS_FILE = 'transport'
TRANSPORT_MAPS_PATH = "/etc/postfix-#{INSTANCE_NAME}/#{TRANSPORT_MAPS_FILE}"

# Domain blacklists
SXL_DBL = node["xgemail"]["sxl_dbl"]
raise "SXL_DBL was nil" if SXL_DBL.nil?

SXL_DBL_RESPONSE_CODES = node["xgemail"]["sxl_dbl_response_codes"]
raise "SXL_DBL_RESPONSE_CODES was nil" if SXL_DBL_RESPONSE_CODES.nil?

# IP blacklists
SXL_RBL = node["xgemail"]["sxl_rbl"]
raise "SXL_RBL was nil" if SXL_RBL.nil?

# SXL returns different codes for IP reputation lookup. The following response codes
# are considered spam, causing the email to be rejected:
#
#  - 127.0.4.1:  SXL_IP_SPAM (Received via a known spam network (SXL lookup))
#  - 127.0.4.5:  SXL_IP_TFX_CS (Received via a known spam network (SXL lookup))
#  - 127.0.4.6:  SXL_IP_TFX_EM (Received via a known exploited mail server (SXL lookup))
#  - 127.0.4.8:  SXL_IP_TFX_EW (Received via a known exploited web server (SXL lookup))
#  - 127.0.4.13: SXL_IP_TFX_SH (Received via a known spam support service (SXL lookup))
#  - 127.0.4.14: SXL_IP_TFX_SS (Received via a known spam source (SXL lookup))
#  - 127.0.4.18: SXL_IP_TFX_MAL (Received via a known source of malware (SXL lookup))
#  - 127.0.4.21: SXL_IP_TFX_PSH (Received via a known source of phishing (SXL lookup))
SXL_RBL_RESPONSE_CODES_A = "127.0.4.[1;5;6;8;13;14;18;21]"

# Hosts authorized to make use of the XCLIENT extension
SMTPD_AUTHORIZED_XCLIENT_HOSTS = node["xgemail"]["smtpd_authorized_xclient_hosts"]

HOP_COUNT_SUBMIT_INSTANCE = node['xgemail']['hop_count_submit_instance']

RBL_REPLY_MAPS_A_FILENAME = 'rbl_reply_maps_a'

execute RBL_REPLY_MAPS_A_FILENAME do
  command lazy {
    print_postmulti_cmd(
        INSTANCE_NAME,
        "postmap 'hash:#{postmulti_config_dir(INSTANCE_NAME)}/#{RBL_REPLY_MAPS_A_FILENAME}'"
    )
  }
  action :nothing
end

RBL_MAP_ENTRY_A = "#{SXL_RBL}=#{SXL_RBL_RESPONSE_CODES_A} " +
    '$rbl_code Service unavailable; $rbl_class [$rbl_what] is blacklisted. ' +
    'Visit https://www.sophos.com/en-us/threat-center/ip-lookup.aspx?ip=$rbl_what ' +
    'to request delisting' +
    "\n"

file RBL_REPLY_MAPS_A_FILENAME do
  path lazy { "#{postmulti_config_dir(INSTANCE_NAME)}/#{RBL_REPLY_MAPS_A_FILENAME}" }
  content RBL_MAP_ENTRY_A
  notifies :run, "execute[#{RBL_REPLY_MAPS_A_FILENAME}]", :immediately
end

# Begin SXL Update

# SXL returns different codes for IP reputation lookup. The following response codes
# are considered spam, causing the email to be rejected:
#
#  - 127.0.4.1:  SXL_IP_SPAM (Received via a known spam network (SXL lookup))
#  - 127.0.4.2:  SXL_IP_PROXY Received via a known proxy IP (SXL lookup))
#  - 127.0.4.3:  SXL_IP_DYNAMIC (Received via a known dynamic IP (SXL lookup))
#  - 127.0.4.4:  SXL_IP_TFX_BOT (Received via a known proxy IP (SXL lookup))
#  - 127.0.4.5:  SXL_IP_TFX_CS Received via a known spam network (SXL lookup))
#  - 127.0.4.13: SXL_IP_TFX_SH (Received via a known spam support service (SXL lookup))
#  - 127.0.4.14: SXL_IP_TFX_SS (Received via a known spam source (SXL lookup))
SXL_RBL_RESPONSE_CODES_B = "127.0.4.[1;2;3;4;5;13;14]"
RBL_REPLY_MAPS_B_FILENAME = 'rbl_reply_maps_b'

execute RBL_REPLY_MAPS_B_FILENAME do
  command lazy {
    print_postmulti_cmd(
        INSTANCE_NAME,
        "postmap 'hash:#{postmulti_config_dir(INSTANCE_NAME)}/#{RBL_REPLY_MAPS_B_FILENAME}'"
    )
  }
  action :nothing
end

RBL_MAP_ENTRY_B = "#{SXL_RBL}=#{SXL_RBL_RESPONSE_CODES_B} " +
    '$rbl_code Service unavailable; $rbl_class [$rbl_what] is blacklisted. ' +
    'Visit https://www.sophos.com/en-us/threat-center/ip-lookup.aspx?ip=$rbl_what ' +
    'to request delisting' +
    "\n"

file RBL_REPLY_MAPS_B_FILENAME do
  path lazy { "#{postmulti_config_dir(INSTANCE_NAME)}/#{RBL_REPLY_MAPS_B_FILENAME}" }
  content RBL_MAP_ENTRY_B
  notifies :run, "execute[#{RBL_REPLY_MAPS_B_FILENAME}]", :immediately
end

# End SXL Update

execute SOFT_RETRY_SENDERS_MAP_FILENAME do
  command lazy {
    print_postmulti_cmd(
        INSTANCE_NAME,
        "postmap 'hash:#{postmulti_config_dir(INSTANCE_NAME)}/#{SOFT_RETRY_SENDERS_MAP_FILENAME}'"
    )
  }
  action :nothing
end

SOFT_RETRY_SENDERS_MAP_ENTRY = "#{WELCOME_MSG_SENDER} DEFER Recipient address unknown\n"

file SOFT_RETRY_SENDERS_MAP_FILENAME do
  path lazy { "#{postmulti_config_dir(INSTANCE_NAME)}/#{SOFT_RETRY_SENDERS_MAP_FILENAME}" }
  content SOFT_RETRY_SENDERS_MAP_ENTRY
  notifies :run, "execute[#{SOFT_RETRY_SENDERS_MAP_FILENAME}]", :immediately
end

if ACCOUNT != 'sandbox'
  GLOBAL_SIGN_DIR = "#{LOCAL_CERT_PATH}/3rdparty/global-sign"
  GLOBAL_SIGN_INTERMEDIARY = "#{GLOBAL_SIGN_DIR}/global-sign-sha256-intermediary.crt"
  GLOBAL_SIGN_CROSSCERT = "#{LOCAL_CERT_PATH}/globalsign-cross-certificate.crt"
  GLOBAL_SIGN_ROOT = "#{LOCAL_CERT_PATH}/globalsign-rsa-ca.crt"

  # Add xgemail certificate
  # api-mcs-mob-prod.crt currently includes the intermediate CA cert in it so
  # GLOBAL_SIGN_INTERMEDIARY is removed from CREATE_SERVER_PEM_COMMAND below.
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

  # Add the recipient BCC config file
  cookbook_file "#{RECIPIENT_BCC_MAPS_PATH}" do
    source "#{RECIPIENT_BCC_MAPS_FILE}"
    mode '0644'
    owner 'root'
    group 'root'
  end

  execute RECIPIENT_BCC_MAPS_PATH do
    command lazy {
      print_postmulti_cmd(
        INSTANCE_NAME,
        "postmap 'hash:#{RECIPIENT_BCC_MAPS_PATH}'"
      )
    }
  end

  # Add the transport config file
  cookbook_file "#{TRANSPORT_MAPS_PATH}" do
    source "#{TRANSPORT_MAPS_FILE}"
    mode '0644'
    owner 'root'
    group 'root'
  end

  execute TRANSPORT_MAPS_PATH do
    command lazy {
      print_postmulti_cmd(
        INSTANCE_NAME,
        "postmap 'hash:#{TRANSPORT_MAPS_PATH}'"
      )
    }
  end

  [
    "hopcount_limit = #{HOP_COUNT_SUBMIT_INSTANCE}",

    'smtpd_upstream_proxy_protocol = haproxy',

    # Server side TLS configuration
    'smtpd_tls_security_level = may',
    'smtpd_tls_ciphers = high',
    'smtpd_tls_mandatory_ciphers = high',
    'smtpd_tls_loglevel = 1',
    'smtpd_tls_received_header = yes',
    "smtpd_tls_cert_file = #{SERVER_PEM_FILE}",
    "smtpd_tls_key_file = #{KEY_FILE}",
    "tls_preempt_cipherlist = yes",

    # Recipient restrictions
    "reject_rbl_client_a = #{SXL_RBL}=#{SXL_RBL_RESPONSE_CODES_A}",
    "reject_rbl_client_b = #{SXL_RBL}=#{SXL_RBL_RESPONSE_CODES_B}",
    'reject_rbl_client = $reject_rbl_client_b',
    'smtpd_recipient_restrictions = ' +
      "reject_rhsbl_reverse_client #{SXL_DBL}=#{SXL_DBL_RESPONSE_CODES}, " +
      "reject_rhsbl_sender #{SXL_DBL}=#{SXL_DBL_RESPONSE_CODES}, " +
      "reject_rhsbl_client #{SXL_DBL}=#{SXL_DBL_RESPONSE_CODES}, " +
      'reject_rbl_client $reject_rbl_client, ' +
      "check_recipient_access hash:$config_directory/#{RECIPIENT_ACCESS_FILENAME} " +
      "hash:$config_directory/#{RECIPIENT_ACCESS_EXTRA_FILENAME}, " +
      "check_sender_access hash:$config_directory/#{SOFT_RETRY_SENDERS_MAP_FILENAME}, " +
      'reject',

    # Sender restrictions
    'smtpd_sender_restrictions = ' +
      "reject_non_fqdn_sender",

    # RBL response configuration
    "rbl_reply_maps=hash:$config_directory/#{RBL_REPLY_MAPS_B_FILENAME}",

    'smtpd_relay_restrictions = ' +
      'permit_auth_destination, ' +
      "check_sender_access hash:$config_directory/#{SOFT_RETRY_SENDERS_MAP_FILENAME}, " +
      'reject',

    "smtpd_authorized_xclient_hosts = #{SMTPD_AUTHORIZED_XCLIENT_HOSTS}",
    "recipient_bcc_maps=hash:#{RECIPIENT_BCC_MAPS_PATH}",
    "transport_maps=hash:#{TRANSPORT_MAPS_PATH}",
    # To allow plus sign within recipient's email address
    "recipient_delimiter = +"
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end

  include_recipe 'sophos-cloud-xgemail::setup_dh_params'
  include_recipe 'sophos-cloud-xgemail::install_jilter_inbound'
  include_recipe 'sophos-cloud-xgemail::setup_flag_toggle_internet_submit'
  include_recipe 'sophos-cloud-xgemail::setup_routing_managers'
  include_recipe 'sophos-cloud-xgemail::setup_internet_submit_domain_updater_cron'
  include_recipe 'sophos-cloud-xgemail::setup_internet_submit_recipient_updater_cron'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_producer'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_multi_policy_service'
  include_recipe 'sophos-cloud-xgemail::setup_push_policy_submit_toggle'
  include_recipe 'sophos-cloud-xgemail::setup_msghistory_event_dir'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_sender_and_recipient_block'
  include_recipe 'sophos-cloud-xgemail::setup_internet_submit_bulk_release_post_quarantine'

else
  [
    # RBL response configuration
    "rbl_reply_maps=hash:$config_directory/#{RBL_REPLY_MAPS_B_FILENAME}"
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end

  include_recipe 'sophos-cloud-xgemail::setup_flag_toggle_internet_submit'
  include_recipe 'sophos-cloud-xgemail::setup_routing_managers'
  include_recipe 'sophos-cloud-xgemail::setup_internet_submit_domain_updater_cron'
  include_recipe 'sophos-cloud-xgemail::setup_internet_submit_recipient_updater_cron'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_producer'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_utils_structure'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_processors_structure'
  include_recipe 'sophos-cloud-xgemail::setup_xgemail_multi_policy_service'
  include_recipe 'sophos-cloud-xgemail::setup_internet_submit_bulk_release_post_quarantine'
end
