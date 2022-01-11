#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_message_history_files_cleanup_cron
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs cron job to clean message history related files
#

# Include Helper library


MH_MAIL_INFO_STORAGE_DIR  = node['xgemail']['mh_mail_info_storage_dir']
NODE_TYPE                 = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

# add the cron job in all 14 delivery servers
if NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'customer-xdelivery' || NODE_TYPE == 'internet-delivery' || NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'warmup-delivery' || NODE_TYPE == 'beta-delivery' || NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'xdelivery' || NODE_TYPE == 'internet-xdelivery' || NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-xdelivery' || NODE_TYPE == 'beta-xdelivery' || NODE_TYPE == 'delta-xdelivery'||
    NODE_TYPE == 'encryption-delivery' || NODE_TYPE == 'mf-inbound-delivery' || NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' || NODE_TYPE == 'mf-outbound-xdelivery'
    # this is a housekeeping job only. the files in the dir will be deleted by the delivery event processor within minutes.
    # cron job deletes files older than 6 days;  based on default maximal_queue_lifetime postfix conf of 5 days
    cron "#{INSTANCE_NAME}-mh-cleanup-cron" do
      hour '*/1'
      user 'root'
      command "find #{MH_MAIL_INFO_STORAGE_DIR} -type f -mtime +6 -delete"
    end

end
