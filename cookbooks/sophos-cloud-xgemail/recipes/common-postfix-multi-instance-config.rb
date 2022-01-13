#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: common-postfix-multi-instance-config
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures common properties for non-default instance of Postfix
#
# It will usually be included from the recipe that defines that non-default instance
#

ACCOUNT =  node['sophos_cloud']['environment']

ACCOUNT_NAME = node['sophos_cloud']['account_name']

require 'aws-sdk'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Recipe.send(:include, ::SophosCloudXgemail::AwsHelper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

SMTPD_PORT = INSTANCE_DATA[:port]
raise "Invalid smtpd port for node type [#{NODE_TYPE}]" if SMTPD_PORT.nil?

MSG_SIZE_LIMIT = INSTANCE_DATA[:msg_size_limit]
raise "Invalid message size limit for node type [#{NODE_TYPE}]" if MSG_SIZE_LIMIT.nil?

RCPT_SIZE_LIMIT = INSTANCE_DATA[:rcpt_size_limit]
raise "Invalid rcpt size limit for node type [#{NODE_TYPE}]" if RCPT_SIZE_LIMIT.nil?

FILE_CACHE_DIR = ::Chef::Config[:file_cache_path]

TLS_HIGH_CIPHERLIST = node['xgemail']['tls_high_cipherlist']

if ACCOUNT_NAME == 'legacy'
  INSTANCE_HOST_NAME = get_hostname(NODE_TYPE)
else
  INSTANCE_HOST_NAME = get_fsc_hostname(NODE_TYPE)

  template 'aws config' do
    path '/root/.aws/config'
    source 'aws_config.erb'
    mode '0600'
    owner 'root'
    group 'root'
    variables(
      :aws_region => node['sophos_cloud']['region'],
      :station_vpc_name => node['xgemail']['station_vpc_name'],
      :cross_account_role => node['sophos_cloud']['station_account_role_arn']
    )
  end
  ENV['STATION_PROFILE'] = node['xgemail']['station_vpc_name']
end

POSTFIX_DEFAULT_PROCESS_LIMIT = node["xgemail"]["postfix_default_process_limit"]

CONFIGURATION_COMMANDS =
  node['xgemail']['common_instance_config_params'] +
  node['xgemail']['no_local_delivery_config_params'] +
  [
    "myhostname = #{INSTANCE_HOST_NAME}",
    "mailbox_size_limit = #{MSG_SIZE_LIMIT + 1024}",
    "message_size_limit = #{MSG_SIZE_LIMIT}",
    "queue_minfree = #{MSG_SIZE_LIMIT * 10}",
    "default_process_limit = #{POSTFIX_DEFAULT_PROCESS_LIMIT}",
    "tls_high_cipherlist = #{TLS_HIGH_CIPHERLIST}",
    "smtpd_recipient_limit = #{RCPT_SIZE_LIMIT}",
    "smtpd_recipient_overshoot_limit = 1",
    "default_destination_recipient_limit = #{RCPT_SIZE_LIMIT}",
    'mynetworks_style=subnet',
    'smtpd_discard_ehlo_keywords = silent-discard, dsn',
    'notify_classes ='
  ]

# Sandbox only
if ACCOUNT == 'sandbox'
  # Create and ignore errors in case of sandbox
  MULTI_CREATE_GUARD = ::File.join( FILE_CACHE_DIR, ".create-postfix-instance-#{INSTANCE_NAME}" )
  execute "#{print_postmulti_create( INSTANCE_NAME )} && touch #{MULTI_CREATE_GUARD}" do
    creates MULTI_CREATE_GUARD
    ignore_failure true
  end

  # Modify stock main.cf for newly created INSTANCE_NAME
  [
      'inet_interfaces = all'
  ].each do | cur |
    execute print_postconf( INSTANCE_NAME, "'#{cur}'")
  end

  # Change ownership tp postfix user
  execute 'change_ownership_to_postfix' do
      user 'root'
      command <<-EOH
          chown -R postfix /var/lib/#{instance_name(INSTANCE_NAME)}
      EOH
  end

  # Update postfix to call jilter as external service
  # only for submit instances
  if NODE_TYPE == 'internet-submit' || NODE_TYPE == 'mf-inbound-submit'
    [
        'smtpd_milters = inet:jilter-inbound:9876',
        'milter_connect_macros = {client_addr}, {j}',
        'milter_end_of_data_macros = {i}'
    ].each do | cur |
        execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
      end
  else
    if NODE_TYPE == 'customer-submit' || NODE_TYPE == 'mf-outbound-submit'
      [
          'smtpd_milters = inet:jilter-outbound:9876',
          'milter_connect_macros = {client_addr}, {j}',
          'milter_end_of_data_macros = {i}'
      ].each do | cur |
        execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
      end
    end
  end

else
  # Create new instance
  MULTI_CREATE_GUARD = ::File.join( FILE_CACHE_DIR, ".create-postfix-instance-#{INSTANCE_NAME}" )
  execute "#{print_postmulti_create( INSTANCE_NAME )} && touch #{MULTI_CREATE_GUARD}" do
    creates MULTI_CREATE_GUARD
  end
end

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end

[
  # Revert to default value for 'master_service_disable'
  'master_service_disable',

  # Revert to default for inet_interfaces
  'inet_interfaces'
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -X '#{cur}'" )
end

[
  # Remove default smtp/inet service
  'smtp/inet'
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -MX '#{cur}'" )
end

[
  # Configure assigned SMTPD port
  "#{SMTPD_PORT}/inet = #{SMTPD_PORT} inet n - n - - smtpd"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -M '#{cur}'" )
end

ruby_block 'cleanup_config_files' do
  block do
    cleanup_main_cf INSTANCE_NAME
    cleanup_master_cf INSTANCE_NAME
  end
end

# Enable new instance
execute print_postmulti_enable( INSTANCE_NAME )
