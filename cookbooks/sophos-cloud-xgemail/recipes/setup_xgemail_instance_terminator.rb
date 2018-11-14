#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_instance_terminator
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs a Python script that is executed by a SSM Command in the event of an EC2 Instance Termination Lifecycle Hook
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

XGEMAIL_FILES_DIR       = node['xgemail']['xgemail_files_dir']
INSTANCE_ID             = node['ec2']['instance_id']
AWS_REGION              = node['sophos_cloud']['region']
ACCOUNT                 = node['sophos_cloud']['environment']
ALARM_TOPIC_ARN         = node['xgemail']['alarm_topic_arn']
CONSUMER_SERVICE_NAME   = node['xgemail']['sqs_message_consumer_service_name']
SNS_POLICY_ARN          = node['xgemail']['xgemail_policy_arn']
SQS_POLICY_QUEUE_NAME   = "#{ACCOUNT}-xgemail-policy-#{INSTANCE_ID}"


directory XGEMAIL_FILES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

# Write script to script path on instance
template "#{XGEMAIL_FILES_DIR}/instance-terminator.py" do
  source 'instance-terminator.py.erb'
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :alarm_topic_arn => ALARM_TOPIC_ARN,
    :aws_region => AWS_REGION,
    :sqs_consumer_service_name => CONSUMER_SERVICE_NAME,
    :sns_policy_arn => SNS_POLICY_ARN,
    :sqs_policy_queue_name => SQS_POLICY_QUEUE_NAME
  )
end

# Add rsyslog config file to redirect lifecycle messages to its own log file.
file '/etc/rsyslog.d/00-xgemail-lifecycle.conf' do
  content "if $syslogtag == '[instance-terminator]' and $syslogseverity <= '5' then /var/log/xgemail/lifecycle.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end