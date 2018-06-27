#
# Cookbook Name:: ${<COOKBOOK>}
# Recipe:: setup_xgemail_sqs_lifecycle_poller_cron.rb
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs cron job to poll xgemail sqs lifecycle events queue for termination notifications
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

CRON_JOB_TIMEOUT      = node['xgemail']['cron_job_timeout']
# Custom cron frequency for Lifecycle SQS poller
CRON_MINUTE_FREQUENCY = node['xgemail']['xgemail_sqs_lifecycle_poller_cron_minute_frequency']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']
INSTANCE_ID           = node['ec2']['instance_id']

# SQS consumer settings specific to Lifecycle Events queue
AWS_REGION = node['sophos_cloud']['region']
ACCOUNT = node['sophos_cloud']['environment']
SNS_LIFECYCLE_TOPIC_ARN = node['xgemail']['lifecycle_topic_arn']
SQS_MAX_NUMBER_OF_MESSAGES = node['xgemail']['sqs_lifecycle_poller_max_number_of_messages']
SQS_POLLER_VISIBILITY_TIMEOUT = node['xgemail']['sqs_lifecycle_poller_visibility_timeout']
SQS_POLLER_WAIT_TIME_SECONDS = node['xgemail']['sqs_lifecycle_poller_wait_time_seconds']
SQS_POLLER_MESSAGE_RETENTION_PERIOD = node['xgemail']['sqs_lifecycle_poller_message_retention_period']
SQS_LIFECYCLE_QUEUE_NAME = "#{ACCOUNT}-xgemail-lifecycle-#{INSTANCE_ID}"
CONSUMER_SERVICE_NAME = node['xgemail']['sqs_message_consumer_service_name']
SNS_POLICY_ARN         = node['xgemail']['xgemail_policy_arn']
SQS_POLICY_QUEUE_NAME  = "#{ACCOUNT}-xgemail-policy-#{INSTANCE_ID}"

ALARM_TOPIC_ARN       = node['xgemail']['alarm_topic_arn']
PACKAGE_DIR           = "#{XGEMAIL_FILES_DIR}/xgemail-sqs-lifecycle-poller-cron"
CRON_SCRIPT           = 'xgemail.sqs.lifecycle.poller.py'
CRON_SCRIPT_PATH      = "#{PACKAGE_DIR}/#{CRON_SCRIPT}"

#
sqs = ::Aws::SQS::Client.new(region: AWS_REGION)
sns = ::Aws::SNS::Client.new(region: AWS_REGION)

queue_url = sqs.create_queue({
  queue_name: SQS_LIFECYCLE_QUEUE_NAME,
  attributes: {
    'MessageRetentionPeriod' => SQS_POLLER_MESSAGE_RETENTION_PERIOD,
    'VisibilityTimeout' => SQS_POLLER_VISIBILITY_TIMEOUT
  }
}).queue_url

# Get the queue's ARN.
queue_arn = sqs.get_queue_attributes({
  queue_url: queue_url,
  attribute_names: ["QueueArn"]
}).attributes["QueueArn"]
# Setup SNS and SQS Subscription
subscription_arn = sns.subscribe({
  topic_arn: SNS_LIFECYCLE_TOPIC_ARN,
  protocol: "sqs",
  endpoint: queue_arn
}).subscription_arn
# Set SQS Queue Policy
sqs.set_queue_attributes(
    queue_url: queue_url,
    attributes: {
      "Policy" => {
        "Version" => "2012-10-17",
        "Statement" => [
          {
            "Effect" => "Allow",
            "Principal" => "*",
            "Action" => "sqs:SendMessage",
            "Resource" => "#{queue_arn}",
            "Condition" => {
              "ArnEquals" => {
                "aws:SourceArn" => "#{SNS_LIFECYCLE_TOPIC_ARN}"
              }
            }
          }
        ]
      }.to_json
    }
  )

directory XGEMAIL_FILES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

cookbook_file "#{PACKAGE_DIR}/pre_termination.py" do
    source 'pre_termination.py'
    owner 'root'
    group 'root'
    mode '0750'
    action :create
end

# Setup cron script execution
execute CRON_SCRIPT_PATH do
  user 'root'
  action :nothing
end

# Write script to script path on instance
template CRON_SCRIPT_PATH do
  source "#{CRON_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :alarm_topic_arn => ALARM_TOPIC_ARN,
    :aws_region => AWS_REGION,
    :instance_id => INSTANCE_ID,
    :lifecycle_topic_subscription_arn => subscription_arn,
    :sqs_lifecycle_poller_max_number_of_messages => SQS_MAX_NUMBER_OF_MESSAGES,
    :sqs_lifecycle_url => queue_url,
    :sqs_lifecycle_poller_visibility_timeout => SQS_POLLER_VISIBILITY_TIMEOUT,
    :sqs_lifecycle_poller_wait_time_seconds => SQS_POLLER_WAIT_TIME_SECONDS,
    :sqs_consumer_service_name => CONSUMER_SERVICE_NAME,
    :sns_policy_arn => SNS_POLICY_ARN,
    :sqs_policy_queue_name => SQS_POLICY_QUEUE_NAME
  )
  notifies :run, "execute[#{CRON_SCRIPT_PATH}]", :immediately
end

# Add rsyslog config file to redirect lifecycle messages to its own log file.
file '/etc/rsyslog.d/00-xgemail-lifecycle.conf' do
  content "if $syslogtag == '[lifecycle-poller]' and $syslogseverity <= '5' then /var/log/xgemail/lifecycle.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end

# Add script to crontab
cron "#{INSTANCE_NAME}-lifecycle-cron" do
  minute "1-59/#{CRON_MINUTE_FREQUENCY}"
  user 'root'
  command "source /etc/profile && timeout #{CRON_JOB_TIMEOUT} flock --nb /var/lock/#{CRON_SCRIPT}.lock -c '#{CRON_SCRIPT_PATH}' >/dev/null 2>&1"
end
