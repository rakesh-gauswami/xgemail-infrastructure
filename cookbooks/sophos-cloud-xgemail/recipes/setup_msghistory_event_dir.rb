#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_msghistory_event_dir
#
# Copyright 2020, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe creates directory for message history storage

MSG_HISTORY_EVENT_DIR     = node['xgemail']['mh_event_storage_dir']
NODE_TYPE                 = node['xgemail']['cluster_type']
SERVICE_USER              = node['xgemail']['jilter_user']
MSG_HISTORY_GROUP         = node['xgemail']['mh_group_name']
MESSAGEPROCESSOR_USER     = node['xgemail']['sqs_message_processor_user']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

# create mh mail info storage directory in submit servers
if NODE_TYPE == 'internet-submit' || NODE_TYPE == 'customer-submit' || NODE_TYPE == 'encryption-submit' 

    group MSG_HISTORY_GROUP do
      members [SERVICE_USER, MESSAGEPROCESSOR_USER] 
    end

    # Create dir where Jilter writes accepted events temporarily for producers to read.
    directory MSG_HISTORY_EVENT_DIR do
      mode '0777'
      owner SERVICE_USER
      group MSG_HISTORY_GROUP
      recursive true
    end
       
    # cron job delete files older than 6 hours (720 min) every 1 hour
    cron "#{INSTANCE_NAME}-mh-cleanup-cron" do
      hour '*/1'
      user 'root'
      command "find #{MSG_HISTORY_EVENT_DIR} -type f -mmin +720 -delete"
    end    
end