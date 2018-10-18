#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-encryption-submit-queue
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures the postfix instance for submitting messages from the encryption service
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'encryption-submit'
  return
end

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

POSTFIX_INSTANCE = 'encryption-submit';
INSTANCE_DATA = node['xgemail']['postfix_instance_data'][POSTFIX_INSTANCE]
raise "Unsupported node type [#{POSTFIX_INSTANCE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{POSTFIX_INSTANCE}]" if INSTANCE_NAME.nil?

include_recipe 'sophos-cloud-xgemail::common-postfix-multi-instance-config'

LOCAL_CERT_PATH = node['sophos_cloud']['local_cert_path']
LOCAL_KEY_PATH = node['sophos_cloud']['local_key_path']

CERT_NAME = node['xgemail']['cert']

CERT_FILE = "#{LOCAL_CERT_PATH}/#{CERT_NAME}.crt"
KEY_FILE = "#{LOCAL_KEY_PATH}/#{CERT_NAME}.key"

SERVER_PEM_FILE = "#{LOCAL_CERT_PATH}/server.pem"

# Domain blacklists
#SXL_DBL = node["xgemail"]["sxl_dbl"]
#raise "SXL_DBL was nil" if SXL_DBL.nil?

#SXL_DBL_RESPONSE_CODES = node["xgemail"]["sxl_dbl_response_codes"]
#raise "SXL_DBL_RESPONSE_CODES was nil" if SXL_DBL_RESPONSE_CODES.nil?

# IP blacklists
#SXL_RBL = node["xgemail"]["sxl_rbl"]
#raise "SXL_RBL was nil" if SXL_RBL.nil?

# SXL returns different return codes and only some of them will be considered
# when making a spam/not spam decision. The following response codes will be
# considered:
#  - 127.0.4.1:  SXL_IP_SPAM (Received via a known spam network (SXL lookup))
#  - 127.0.4.5:  SXL_IP_TFX_CS (Received via a known spam network (SXL lookup))
#  - 127.0.4.6:  SXL_IP_TFX_EM (Received via a known exploited mail server (SXL lookup))
#  - 127.0.4.8:  SXL_IP_TFX_EW (Received via a known exploited web server (SXL lookup))
#  - 127.0.4.13: SXL_IP_TFX_SH (Received via a known spam support service (SXL lookup))
#  - 127.0.4.14: SXL_IP_TFX_SS (Received via a known spam source (SXL lookup))
#  - 127.0.4.18: SXL_IP_TFX_MAL (Received via a known source of malware (SXL lookup))
#  - 127.0.4.21: SXL_IP_TFX_PSH (Received via a known source of phishing (SXL lookup))
SXL_RBL_RESPONSE_CODES = "127.0.4.[1;5;6;8;13;14;18;21]"

GLOBAL_SIGN_DIR = "#{LOCAL_CERT_PATH}/3rdparty/global-sign"
GLOBAL_SIGN_INTERMEDIARY = "#{GLOBAL_SIGN_DIR}/global-sign-sha256-intermediary.crt"
GLOBAL_SIGN_ROOT = "#{GLOBAL_SIGN_DIR}/global-sign-root.crt"

# Add xgemail certificate
remote_file "/etc/ssl/certs/#{CERT_NAME}.crt" do
  source "file:///tmp/sophos/certificates/api-mcs-mob-prod.crt"
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
  "'#{GLOBAL_SIGN_INTERMEDIARY}' " +
  "'#{GLOBAL_SIGN_ROOT}' " +
  "> '#{SERVER_PEM_FILE}'"

file SERVER_PEM_FILE do
  owner 'root'
  group 'root'
  mode '0444'
  action :create
end

execute CREATE_SERVER_PEM_COMMAND

#RBL_REPLY_MAPS_FILENAME = 'rbl_reply_maps'

#execute RBL_REPLY_MAPS_FILENAME do
#  command lazy {
#    print_postmulti_cmd(
#      INSTANCE_NAME,
#      "postmap 'hash:#{postmulti_config_dir(INSTANCE_NAME)}/#{RBL_REPLY_MAPS_FILENAME}'"
#    )
#  }
#  action :nothing
#end

#RBL_MAP_ENTRY = "#{SXL_RBL}=#{SXL_RBL_RESPONSE_CODES} " +
#  '$rbl_code Service unavailable; $rbl_class [$rbl_what] is blacklisted. ' +
#  'Visit https://www.sophos.com/en-us/threat-center/ip-lookup.aspx?ip=$rbl_what ' +
#  'to request delisting' +
#  "\n"

#file RBL_REPLY_MAPS_FILENAME do
#  path lazy { "#{postmulti_config_dir(INSTANCE_NAME)}/#{RBL_REPLY_MAPS_FILENAME}" }
#  content RBL_MAP_ENTRY
#  notifies :run, "execute[#{RBL_REPLY_MAPS_FILENAME}]", :immediately
#end

CONFIGURATION_COMMANDS =
  [
    'smtpd_upstream_proxy_protocol = haproxy',

    # Server side TLS configuration
    'smtpd_tls_security_level = encrypt',
    'smtpd_tls_ciphers = high',
    'smtpd_tls_mandatory_ciphers = high',
    'smtpd_tls_loglevel = 1',
    'smtpd_tls_received_header = yes',
    'smtpd_tls_cert_file = #{SERVER_PEM_FILE}',
    'smtpd_tls_key_file = #{KEY_FILE}',

    # Recipient restrictions
    #'smtpd_recipient_restrictions = ' +
    #  "reject_rhsbl_reverse_client #{SXL_DBL}=#{SXL_DBL_RESPONSE_CODES}, " +
    #  "reject_rhsbl_sender #{SXL_DBL}=#{SXL_DBL_RESPONSE_CODES}, " +
    #  "reject_rhsbl_client #{SXL_DBL}=#{SXL_DBL_RESPONSE_CODES}, " +
    #  "reject_rbl_client #{SXL_RBL}=#{SXL_RBL_RESPONSE_CODES}, " +
    #  'permit',

    #     'relay_domains = static:ALL',

    # Sender restrictions
    #'smtpd_sender_restrictions = ' +
    #  "reject_non_fqdn_sender",

    # RBL response configuration
    #"rbl_reply_maps=hash:$config_directory/#{RBL_REPLY_MAPS_FILENAME}"
  ]

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end


include_recipe 'sophos-cloud-xgemail::setup_dh_params'

# TODO Add the script for encryption-submit jilter setup and message splitting
#include_recipe 'sophos-cloud-xgemail::install_jilter_outbound'
#include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_producer'