#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_mf_inbound_utils_structure
#
# Copyright 2021, Sophos
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
BULKSENDER_FORMATTER = 'bulksenderformatter.py'
BULK_SENDER_ACTION = "bulk_sender_action.py"
DELIVERY_DIRECTOR_FORMATTER = "deliverydirectorthreshold.py"
TELEMETRY_DATA_FORMATTER = "telemetrydataformatter.py"
STATION_ACCOUNT_ROLE_ARN = node['sophos_cloud']['station_account_role_arn']

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

template 'awshandler' do
  path "#{XGEMAIL_UTILS_DIR}/awshandler.py"
  source 'awshandler.py.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :station_account_role_arn => STATION_ACCOUNT_ROLE_ARN
  )
end

[
  'allowblockimporter.py',
  'configformatter.py',
  'diskutils.py',
  'formatterutils.py',
  'gziputils.py',
  'impersonation_updater.py',
  'mailinfoformatter.py',
  'messageformatter.py',
  'messagehistory.py',
  'messagehistoryformatter.py',
  'metadataformatter.py',
  'multipolicyreaderutils.py',
  'nonrecoverableexception.py',
  'notadirectoryexception.py',
  'recipientsplitconfig.py',
  'recoverableexception.py',
  'routingmanager.py',
  'scaneventattributes.py',
  'uuidutils.py',
  'rfxrecoveryutils.py',
  'get_metadata_from_msghistory_config.py',
  'toggle_flag_s3.py',
  'get_prefix_restructure_config.py'
].each do | cur |
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{cur}" do
    source cur
    mode '0644'
    owner 'root'
    group 'root'
  end
end

if NODE_TYPE == 'mf-inbound-submit' or NODE_TYPE == 'journal-submit'
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{POLICY_FORMATTER}" do
    source 'policyformatter.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{BULK_SENDER_ACTION}" do
    source 'bulk_sender_action.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
elsif NODE_TYPE == 'mf-inbound-delivery'
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{TRANSPORT_ROUTE_CONFIG}" do
    source 'transportrouteconfig.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
  cookbook_file "#{XGEMAIL_UTILS_DIR}/#{TELEMETRY_DATA_FORMATTER}" do
    source 'telemetrydataformatter.py'
    mode '0644'
    owner 'root'
    group 'root'
  end
else
  #do nothing
end

if NODE_TYPE == 'mf-inbound-delivery' or NODE_TYPE == 'mf-inbound-xdelivery'
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