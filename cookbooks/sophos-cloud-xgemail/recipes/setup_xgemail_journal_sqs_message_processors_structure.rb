#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_journal_sqs_message_processors_structure
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Common configuration for python scripts used by different xgemail components
#

SERVICE_USER = node['xgemail']['sqs_message_processor_user']

SQS_MESSAGE_PROCESSOR_DIR         = node['xgemail']['sqs_message_processor_dir']
SQS_MESSAGE_PROCESSOR_COMMON_DIR  = node['xgemail']['sqs_message_processor_common_dir']

[
  SQS_MESSAGE_PROCESSOR_DIR,
  SQS_MESSAGE_PROCESSOR_COMMON_DIR
].each do | cur |
  directory cur do
    mode '0755'
    owner 'root'
    group 'root'
    recursive true
  end
end

# Create user for sqs message processors
user SERVICE_USER do
  system true
  shell '/sbin/nologin'
end

# Ensure __init__py file is created in python module
file "#{SQS_MESSAGE_PROCESSOR_COMMON_DIR}/__init__.py" do
  mode '0644'
  owner 'root'
  group 'root'
end

[
  'messagehistoryevent.py',
  'metadata.py',
  'sqsmessage.py'
].each do | cur |
  cookbook_file "#{SQS_MESSAGE_PROCESSOR_COMMON_DIR}/#{cur}" do
    source cur
    mode '0644'
    owner 'root'
    group 'root'
  end
end