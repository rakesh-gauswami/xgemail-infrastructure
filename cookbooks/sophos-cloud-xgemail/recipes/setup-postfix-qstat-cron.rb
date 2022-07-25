#
# Cookbook Name:: ${<COOKBOOK>}
# Recipe:: setup-postfix-qstat-cron
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#
# This recipe installs cron job to push postfix queue sizes to cloudwatch metrics
#

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

AWS_REGION            = node['sophos_cloud']['region']
INSTANCE_ID           = node['ec2']['instance_id']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']
PACKAGE_DIR           = "#{XGEMAIL_FILES_DIR}/postfix-qstat-cron"
CRON_SCRIPT           = 'postfix-qstat.sh'
CRON_SCRIPT_PATH      = "#{PACKAGE_DIR}/#{CRON_SCRIPT}"

directory PACKAGE_DIR do
  mode "0755"
  owner "root"
  group "root"
end

template CRON_SCRIPT_PATH do
  source "#{CRON_SCRIPT}.erb"
  mode "0750"
  owner "root"
  group "root"
  variables(
    :aws_region => AWS_REGION,
    :instance_id => INSTANCE_ID,
    :instance_name => INSTANCE_NAME
  )
end

cron CRON_SCRIPT_PATH do
  minute "*"
  user "root"
  command "source /etc/profile && timeout 60 '#{CRON_SCRIPT_PATH}' >/dev/null 2>&1"
end
