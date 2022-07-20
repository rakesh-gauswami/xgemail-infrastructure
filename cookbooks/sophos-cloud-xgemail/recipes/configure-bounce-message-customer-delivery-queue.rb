#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-bounce-message-customer-delivery-queue
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures master.cf on customer delivery and extended delivery postfix instance
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

if NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'xdelivery' || NODE_TYPE == 'customer-xdelivery' || NODE_TYPE == 'encryption-delivery'
  [
    # add xgemail_do_sender_bounce in main.cf to suppress bounces so NDR and bounces can be disabled.
    'xgemail_do_sender_bounce = no'
  ].each do | cur |
    execute print_postmulti_cmd(INSTANCE_NAME, "postconf -e '#{cur}'" )
  end
end
