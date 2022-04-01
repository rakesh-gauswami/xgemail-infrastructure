#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-encryption-submit-queue
#
# Copyright 2021, Sophos
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

SERVER_PEM_FILE = "#{LOCAL_CERT_PATH}/server.pem"

SXL_RBL_RESPONSE_CODES = "127.0.4.[1;5;6;8;13;14;18;21]"

GLOBAL_SIGN_DIR = "#{LOCAL_CERT_PATH}/3rdparty/global-sign"
GLOBAL_SIGN_INTERMEDIARY = "#{GLOBAL_SIGN_DIR}/global-sign-sha256-intermediary.crt"
GLOBAL_SIGN_CROSSCERT = "#{LOCAL_CERT_PATH}/globalsign-cross-certificate.crt"
GLOBAL_SIGN_ROOT = "#{LOCAL_CERT_PATH}/globalsign-rsa-ca.crt"

HOP_COUNT_SUBMIT_INSTANCE = node['xgemail']['hop_count_submit_instance']

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

CONFIGURATION_COMMANDS =
  [
    "hopcount_limit = #{HOP_COUNT_SUBMIT_INSTANCE}",

    'smtpd_upstream_proxy_protocol = haproxy',

    # Server side TLS configuration
    'smtpd_tls_security_level = encrypt',
    'smtpd_tls_ciphers = high',
    'smtpd_tls_mandatory_ciphers = high',
    'smtpd_tls_loglevel = 1',
    'smtpd_tls_received_header = yes',
    "smtpd_tls_cert_file = #{SERVER_PEM_FILE}",
    "smtpd_tls_key_file = #{KEY_FILE}",

    'relay_domains = static:ALL',

    'smtpd_sender_restrictions = ' +
        "reject_non_fqdn_sender",
    "xgemail_log_telemetry = yes",
  ]

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end


include_recipe 'sophos-cloud-xgemail::setup_dh_params'

include_recipe 'sophos-cloud-xgemail::install_jilter_encryption'
include_recipe 'sophos-cloud-xgemail::setup_internet_submit_domain_updater_cron'
include_recipe 'sophos-cloud-xgemail::setup_xgemail_encryption_sqs_message_producer'
include_recipe 'sophos-cloud-xgemail::setup_msghistory_event_dir'
