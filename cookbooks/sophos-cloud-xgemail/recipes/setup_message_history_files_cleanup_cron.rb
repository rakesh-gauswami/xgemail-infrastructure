#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_message_history_files_cleanup_cron
#
# Copyright 2020, Sophos
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

if NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'internet-delivery' || NODE_TYPE == 'encryption-delivery' || 
    NODE_TYPE == 'risky-delivery' || NODE_TYPE == 'warmup-delivery' || NODE_TYPE == 'beta-delivery' || NODE_TYPE == 'delta-delivery'

    # cron job delete files older than 1 day (1440 hours) every 1 hour
    cron "#{INSTANCE_NAME}-mh-cleanup-cron" do
      hour '*/1'
      user 'root'
      command "find #{MH_MAIL_INFO_STORAGE_DIR} -type f -mmin +1440 -delete"
    end
  
end
