#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_policy_service.rb
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs a service to poll xgemail policy sqs queues for policy file updates in S3
#

require 'aws-sdk'
require 'json'

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

XGEMAIL_UTILS_DIR           = node['xgemail']['xgemail_utils_files_dir']
XGEMAIL_FILES_DIR           = node['xgemail']['xgemail_files_dir']
INSTANCE_ID                 = node['ec2']['instance_id']
AWS_REGION                  = node['sophos_cloud']['region']
ACCOUNT                     = node['sophos_cloud']['environment']
POLICY_BUCKET_NAME          = node['xgemail']['xgemail_policy_bucket_name']
SNS_POLICY_ARN              = node['xgemail']['xgemail_policy_arn']
PACKAGE_DIR                 = "#{XGEMAIL_FILES_DIR}/xgemail-policy-service"
CONSUMER_UTILS_SCRIPT       = 'policyconsumerutils.py'
CONSUMER_UTILS_SCRIPT_PATH  = "#{PACKAGE_DIR}/#{CONSUMER_UTILS_SCRIPT}"
CONSUMER_SCRIPT             = 'xgemail.policy.consumer.py'
CONSUMER_SCRIPT_PATH        = "#{PACKAGE_DIR}/#{CONSUMER_SCRIPT}"
POLICY_QUEUE_NAME           = "#{ACCOUNT}-xgemail-policy-#{INSTANCE_ID}"
POLLER_SCRIPT               = 'xgemail.sqs.policy.poller.py'
POLLER_SCRIPT_PATH          = "#{PACKAGE_DIR}/#{POLLER_SCRIPT}"
TEMP_FAILURE_CODE           = node['xgemail']['temp_failure_code']

if NODE_TYPE == 'submit'
  POLICY_DIR                  = "spf/domains/"

  CONFIGS = [
      {
          :s3_path_dir        => POLICY_DIR,
          :local_dir          => "#{XGEMAIL_FILES_DIR}/",
          :file_extension     => '.POLICY',
          :maybe_decode_name  => 'false'
      }
  ]

elsif NODE_TYPE == 'customer-submit'
  RELAY_CONTROL_PATH_PREFIX     = 'config/outbound-relay-control'
  SERVICE_PROVIDER_DIR          = "#{RELAY_CONTROL_PATH_PREFIX}/service-providers/"
  GATEWAY_CONFIG_DIR            = "#{RELAY_CONTROL_PATH_PREFIX}/domains/"
  RATE_LIMIT_CONFIG_DIR         = "#{RELAY_CONTROL_PATH_PREFIX}/rate-limit/"
  BLOCK_LIST_CONFIG_DIR         = "#{RELAY_CONTROL_PATH_PREFIX}/block-list/"

  CONFIGS = [
      {
          :s3_path_dir        => GATEWAY_CONFIG_DIR,
          :local_dir          => "#{XGEMAIL_FILES_DIR}/",
          :file_extension     => '.CONFIG'
      },
      {
          :s3_path_dir        => SERVICE_PROVIDER_DIR,
          :local_dir          => "#{XGEMAIL_FILES_DIR}/",
          :file_extension     => '.CONFIG'
      },
      {
          :s3_path_dir        => RATE_LIMIT_CONFIG_DIR,
          :local_dir          => "#{XGEMAIL_FILES_DIR}/",
          :file_extension     => '.CONFIG'
      },
      {
          :s3_path_dir        => BLOCK_LIST_CONFIG_DIR,
          :local_dir          => "#{XGEMAIL_FILES_DIR}/",
          :file_extension     => '.CONFIG'
      }
  ]
else
     #do nothing since this doesn't run on any other nodes
end

POLICY_SQS_POLL_MAX_NUMBER_OF_MESSAGES  = node['xgemail']['sqs_policy_poller_max_number_of_messages']
POLICY_SQS_WAIT_TIME_SECONDS            = node['xgemail']['sqs_policy_poller_wait_time_seconds']
POLICY_SQS_VISIBILITY_TIMEOUT           = node['xgemail']['sqs_policy_poller_visibility_timeout']
POLICY_SQS_MESSAGE_RETENTION_PERIOD     = node['xgemail']['sqs_policy_poller_message_retention_period']
POLICY_SQS_MESSAGE_VISIBILITY_TIMEOUT   = node['xgemail']['sqs_policy_sqs_message_visibility_timeout']
POLICY_POLLER_SERVICE_NAME              = node['xgemail']['sqs_policy_poller_service_name']

#directory for policy services
directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

# Write policy consumer utils
template CONSUMER_UTILS_SCRIPT_PATH do
  source "#{CONSUMER_UTILS_SCRIPT}.erb"
  mode '0644'
  owner 'root'
  group 'root'
  variables(
      :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
end

execute CONSUMER_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write consumer script to consumer script path on an instance
template CONSUMER_SCRIPT_PATH do
  source "#{CONSUMER_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :configs => CONFIGS.to_json,
    :policy_bucket => POLICY_BUCKET_NAME,
    :policy_queue_name => POLICY_QUEUE_NAME,
    :policy_sqs_visibility_timeout => POLICY_SQS_VISIBILITY_TIMEOUT,
    :policy_sqs_msg_retention_period => POLICY_SQS_MESSAGE_RETENTION_PERIOD,
    :sns_policy_arn => SNS_POLICY_ARN,
    :temp_failure_code => TEMP_FAILURE_CODE,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
  notifies :run, "execute[#{CONSUMER_SCRIPT_PATH}]", :immediately
end

# Write poller script to poller script path on an instance
template POLLER_SCRIPT_PATH do
  source "#{POLLER_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :aws_region => AWS_REGION,
    :configs => CONFIGS.to_json,
    :node_type => NODE_TYPE,
    :policy_queue_name => POLICY_QUEUE_NAME,
    :policy_bucket => POLICY_BUCKET_NAME,
    :policy_sqs_max_no_of_msgs => POLICY_SQS_POLL_MAX_NUMBER_OF_MESSAGES,
    :policy_sqs_wait_time_in_seconds => POLICY_SQS_WAIT_TIME_SECONDS,
    :policy_sqs_msg_visibility_timeout => POLICY_SQS_MESSAGE_VISIBILITY_TIMEOUT,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
end

template POLICY_POLLER_SERVICE_NAME do
  path "/etc/init.d/#{POLICY_POLLER_SERVICE_NAME}"
  source 'xgemail.sqs.policy.poller.init.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables(
    :service => POLICY_POLLER_SERVICE_NAME,
    :script_path => POLLER_SCRIPT_PATH,
    :user => 'root'
  )
end

# Add rsyslog config file to redirect policy messages to its own log file.
file '/etc/rsyslog.d/00-xgemail-policy.conf' do
  content "if $syslogtag contains 'policy-' and $syslogseverity <= '5' then /var/log/xgemail/policy.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end

# Add fluentd config file to monitor log file and submit to S3 for Logz.io.
template '/etc/td-agent.d/00-source-policy.conf' do
  source 'fluentd-source-policy.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE
  )
end

service POLICY_POLLER_SERVICE_NAME do
  service_name POLICY_POLLER_SERVICE_NAME
  init_command "/etc/init.d/#{POLICY_POLLER_SERVICE_NAME}"
  supports :restart => true, :start => true, :stop => true, :reload => true
  subscribes :enable, 'template[xgemail-sqs-policy-poller]', :immediately
end

service POLICY_POLLER_SERVICE_NAME do
  action :start
end

