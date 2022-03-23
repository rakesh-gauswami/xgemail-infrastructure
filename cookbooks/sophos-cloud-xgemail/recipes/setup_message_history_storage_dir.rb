#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_message_history_storage_dir
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe creates directory for message history storage

MH_MAIL_INFO_STORAGE_DIR  = node['xgemail']['mh_mail_info_storage_dir']
NODE_TYPE                 = node['xgemail']['cluster_type']
SERVICE_USER              = node['xgemail']['sqs_message_processor_user']

# create mh mail info storage directory in all delivery servers & extended delivery servers
if NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'customer-xdelivery' || NODE_TYPE == 'internet-delivery' || NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'warmup-delivery' || NODE_TYPE == 'beta-delivery' || NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'xdelivery' || NODE_TYPE == 'internet-xdelivery' || NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-xdelivery' || NODE_TYPE == 'beta-xdelivery' || NODE_TYPE == 'delta-xdelivery'||
    NODE_TYPE == 'encryption-delivery' || NODE_TYPE == 'mf-inbound-delivery' || NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' || NODE_TYPE == 'mf-outbound-xdelivery'

    directory MH_MAIL_INFO_STORAGE_DIR do
      mode '0777'
      owner SERVICE_USER
      group SERVICE_USER
      recursive true
    end

end
