#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_mf_inbound_multi_policy_service
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs a service to poll xgemail multi policy sqs queue for policy file updates in S3
#

require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

ACCOUNT                                 = node['sophos_cloud']['environment']
AWS_REGION                              = node['sophos_cloud']['region']
NODE_TYPE                               = node['xgemail']['cluster_type']
POLICY_BUCKET_NAME                      = node['xgemail']['xgemail_policy_bucket_name']
SNS_POLICY_ARN                          = node['xgemail']['xgemail_policy_arn']
TEMP_FAILURE_CODE                       = node['xgemail']['temp_failure_code']
XGEMAIL_EFS_FILES_DIR                   = node['xgemail']['policy_efs_mount_dir']
XGEMAIL_FILES_DIR                       = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR                       = node['xgemail']['xgemail_utils_files_dir']
STATION_VPC_ID                          = node['xgemail']['station_vpc_id']
PACKAGE_DIR                             = "#{XGEMAIL_FILES_DIR}/xgemail-policy-service"
CONSUMER_UTILS_SCRIPT                   = 'policyconsumerutils.py'
MULTI_POLICY_CONSUMER_UTILS_SCRIPT      = 'multipolicyconsumerutils.py'
MULTI_POLICY_CONSUMER_UTILS_SCRIPT_PATH = "#{PACKAGE_DIR}/#{MULTI_POLICY_CONSUMER_UTILS_SCRIPT}"

if ACCOUNT == 'sandbox'
  MULTI_POLICY_QUEUE_NAME               = "sandbox-Xgemail_multi_policy"
else
  MULTI_POLICY_QUEUE_NAME               = "#{STATION_VPC_ID}-Xgemail_multi_policy"
end

if NODE_TYPE == 'mf-inbound-submit'
  POLICY_DIR                  = "config/policies/endpoints/"
  DOMAINS_DIR                 = "config/policies/domains/"

  CONFIGS = [
      {
          :s3_path_dir        => POLICY_DIR,
          :local_dir          => "#{XGEMAIL_EFS_FILES_DIR}/",
          :file_extension     => '.POLICY',
          :maybe_decode_name  => 'false'
      },
      {
          :s3_path_dir        => DOMAINS_DIR,
          :local_dir          => "#{XGEMAIL_EFS_FILES_DIR}/",
          :file_extension     => '',
          :maybe_decode_name  => 'false'
      }
  ]
else
     #do nothing since this doesn't run on any other nodes
end

#directory for multi policy services
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

# Write multi policy consumer utils to the same place as other utils
template MULTI_POLICY_CONSUMER_UTILS_SCRIPT_PATH do
  source "#{CONSUMER_UTILS_SCRIPT}.erb"
  mode '0644'
  owner 'root'
  group 'root'
  variables(
      :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
end

# Add rsyslog config file to redirect policy messages to its own log file.
file '/etc/rsyslog.d/00-xgemail-multi-policy.conf' do
  content "if $syslogtag contains 'policy-' and $syslogseverity <= '5' then /var/log/xgemail/multi-policy.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end