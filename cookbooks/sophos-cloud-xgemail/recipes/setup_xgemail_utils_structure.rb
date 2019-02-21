#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_utils_structure
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Common configuration for python scripts used by different xgemail components
# like submit, delivery and policy etc.

NODE_TYPE = node['xgemail']['cluster_type']

XGEMAIL_FILES_DIR = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR = node['xgemail']['xgemail_utils_files_dir']
POLICY_FORMATTER = 'policyformatter.py'

[
    XGEMAIL_FILES_DIR,
    XGEMAIL_UTILS_DIR
].each do | cur |
  directory cur do
    mode '0755'
    owner 'root'
    group 'root'
    recursive true
  end
end

# Ensure __init__py file is created in python module
file "#{XGEMAIL_UTILS_DIR}/__init__.py" do
  mode '0644'
  owner 'root'
  group 'root'
end

[
    'awshandler.py',
    'diskutils.py',
    'formatterutils.py',
    'gziputils.py',
    'messageformatter.py',
    'messagehistoryformatter.py',
    'metadataformatter.py',
    'multipolicyreaderutils.py',
    'nonrecoverableexception.py',
    'notadirectoryexception.py',
    'recipientsplitconfig.py',
    'recoverableexception.py',
    'routingmanager.py',
    'scaneventattributes.py'
].each do | cur |
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{cur}" do
    source cur
    mode '0644'
    owner 'root'
    group 'root'
  end
end

if NODE_TYPE == 'internet-submit' or NODE_TYPE == 'encryption-submit'
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{POLICY_FORMATTER}" do
    source 'policyformatter.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
elsif NODE_TYPE == 'customer-submit'
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{POLICY_FORMATTER}" do
    source 'outboundpolicyformatter.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
else
  #do nothing
end

if NODE_TYPE == 'customer-delivery' or NODE_TYPE == 'internet-delivery' or
    NODE_TYPE == 'xdelivery' or NODE_TYPE == 'internet-xdelivery' or
    NODE_TYPE == 'encryption-delivery'
  [
      'postfix_injection_response.py',
      'queue_log.py',
      'sns_message_history_delivery_status.py'
  ].each do | cur |
    cookbook_file "#{XGEMAIL_UTILS_DIR}/#{cur}" do
      source cur
      mode '0644'
      owner 'root'
      group 'root'
    end
  end
end
