#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_sqs_message_consumer
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure SQS message consumer service
#

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

SMTPD_PORT = INSTANCE_DATA[:port]
raise "Invalid smtpd port for node type [#{NODE_TYPE}]" if SMTPD_PORT.nil?

ACCOUNT = node['sophos_cloud']['context']
AWS_REGION = node['sophos_cloud']['region']
LOCAL_CERT_PATH = node['sophos_cloud']['local_cert_path']
STATION_VPC_NAME = node['xgemail']['station_vpc_name']

XGEMAIL_UTILS_DIR                       = node['xgemail']['xgemail_utils_files_dir']
SQS_MESSAGE_CONSUMER_WAIT_TIME_SECONDS  = node['xgemail']['sqs_message_consumer_wait_time_seconds']
SQS_MESSAGE_CONSUMER_MAX_NUMBER_OF_MESSAGES = node['xgemail']['sqs_message_consumer_max_number_of_messages']
SQS_MESSAGE_CONSUMER_VISIBILITY_TIMEOUT = node['xgemail']['sqs_message_consumer_visibility_timeout']
SQS_MESSAGE_CONSUMER_INJECT_MTA_HOST    = node['xgemail']['sqs_message_consumer_inject_mta_host']
SQS_MESSAGE_PROCESSOR_DIR               = node['xgemail']['sqs_message_processor_dir']
XGEMAIL_BUCKET_NAME                     = node['xgemail']['xgemail_bucket_name']
XGEMAIL_SNS_SQS_URL                     = node['xgemail']['xgemail_sns_sqs_url']

XGEMAIL_PIC_CA_PATH = "#{LOCAL_CERT_PATH}/hmr-infrastructure-ca.crt"
XGEMAIL_PIC_FQDN = "mail-#{STATION_VPC_NAME.downcase}-#{AWS_REGION}.#{ACCOUNT}.hydra.sophos.com"

include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_processors_structure'

CONSUMER_SCRIPT = 'xgemail_sqs_message_consumer.py'
CONSUMER_SERVICE_NAME = node['xgemail']['sqs_message_consumer_service_name']

CONSUMER_SCRIPT_PATH = "#{SQS_MESSAGE_PROCESSOR_DIR}/#{CONSUMER_SCRIPT}"

SERVICE_USER = node['xgemail']['sqs_message_processor_user']

template CONSUMER_SCRIPT_PATH do
  source 'xgemail.sqs.message.consumer.py.erb'
  mode '0700'
  owner SERVICE_USER
  group SERVICE_USER
  variables(
    :aws_region => AWS_REGION,
    :mta_host => SQS_MESSAGE_CONSUMER_INJECT_MTA_HOST,
    :mta_port => SMTPD_PORT,
    :s3_bucket_name => XGEMAIL_BUCKET_NAME,
    :sns_sqs_url => XGEMAIL_SNS_SQS_URL,
    :sqs_max_number_of_messages => SQS_MESSAGE_CONSUMER_MAX_NUMBER_OF_MESSAGES,
    :sqs_visibility_timeout => SQS_MESSAGE_CONSUMER_VISIBILITY_TIMEOUT,
    :sqs_wait_time_seconds => SQS_MESSAGE_CONSUMER_WAIT_TIME_SECONDS,
    :xgemail_pic_ca_path => XGEMAIL_PIC_CA_PATH,
    :xgemail_pic_fqdn => XGEMAIL_PIC_FQDN,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR
  )
end

template 'xgemail-sqs-consumer' do
  path "/etc/init.d/#{CONSUMER_SERVICE_NAME}"
  source 'xgemail.sqs.message.consumer.init.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables(
    :service => CONSUMER_SERVICE_NAME,
    :script_path => CONSUMER_SCRIPT_PATH,
    :user => SERVICE_USER
  )
end

# Add rsyslog config file to redirect sqsmsgconsumer messages to its own log file.
file '/etc/rsyslog.d/00-xgemail-sqsmsgconsumer.conf' do
  content "if $syslogtag == '[sqsmsgconsumer]' then /var/log/xgemail/sqsmsgconsumer.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end

# Add fluentd config file to monitor log file and submit to S3 for Logz.io.
template '/etc/td-agent.d/00-source-sqsmsgconsumer.conf' do
  source 'fluentd-source-sqsmsgconsumer.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE
  )
end

service 'xgemail-sqs-consumer' do
  service_name CONSUMER_SERVICE_NAME
  init_command "/etc/init.d/#{CONSUMER_SERVICE_NAME}"
  supports :restart => true, :start => true, :stop => true, :reload => true
  subscribes :enable, 'template[xgemail-sqs-consumer]', :immediately
end
