#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_utils_structure
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Common configuration for python scripts used by different xgemail components
# like submit, delivery and policy etc.

NODE_TYPE = node['xgemail']['cluster_type']

XGEMAIL_FILES_DIR = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR = node['xgemail']['xgemail_utils_files_dir']
POLICY_FORMATTER = 'policyformatter.py'
BLOCKED_SENDER_API = 'blocked_sender_api.py'
TRANSPORT_ROUTE_CONFIG = 'transportrouteconfig.py'

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
    'allowblockimporter.py',
    'awshandler.py',
    'configformatter.py',
    'deliverydirector_config_updater.py',
    'diskutils.py',
    'formatterutils.py',
    'gziputils.py',
    'impersonation_updater.py',
    'messageformatter.py',
    'messagehistoryformatter.py',
    'metadataformatter.py',
    'multipolicyreaderutils.py',
    'nonrecoverableexception.py',
    'notadirectoryexception.py',
    'recipientsplitconfig.py',
    'recoverableexception.py',
    'routingmanager.py',
    'scaneventattributes.py',
    'uuidutils.py'
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
    source 'policyformatter.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{BLOCKED_SENDER_API}" do
    source 'blocked_sender_api.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
elsif NODE_TYPE == 'customer-delivery' or NODE_TYPE == 'internet-delivery' or
       NODE_TYPE == 'risky-delivery' or NODE_TYPE == 'encryption-delivery'
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{TRANSPORT_ROUTE_CONFIG}" do
    source 'transportrouteconfig.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
else
  #do nothing
end

if NODE_TYPE == 'customer-delivery' or NODE_TYPE == 'internet-delivery' or
    NODE_TYPE == 'xdelivery' or NODE_TYPE == 'internet-xdelivery' or
    NODE_TYPE == 'encryption-delivery' or NODE_TYPE == 'risky-delivery' or
    NODE_TYPE == 'risky-xdelivery'
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