#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_sqs_message_consumer
#
# Copyright 2021, Sophos
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
ACCOUNT_NAME = node['sophos_cloud']['account_name']
AWS_REGION = node['sophos_cloud']['region']
LOCAL_CERT_PATH = node['sophos_cloud']['local_cert_path']
PARENT_ACCOUNT_NAME = node['sophos_cloud']['parent_account_name']
STATION_VPC_NAME = node['xgemail']['station_vpc_name']
CONNECTIONS_BUCKET = node['sophos_cloud']['connections']

XGEMAIL_FILES_DIR                       = node['xgemail']['xgemail_files_dir']
XGEMAIL_UTILS_DIR                       = node['xgemail']['xgemail_utils_files_dir']
SQS_MESSAGE_CONSUMER_WAIT_TIME_SECONDS  = node['xgemail']['sqs_message_consumer_wait_time_seconds']
SQS_MESSAGE_CONSUMER_MAX_NUMBER_OF_MESSAGES = node['xgemail']['sqs_message_consumer_max_number_of_messages']
SQS_MESSAGE_CONSUMER_VISIBILITY_TIMEOUT = node['xgemail']['sqs_message_consumer_visibility_timeout']
SQS_MESSAGE_CONSUMER_INJECT_MTA_HOST    = node['xgemail']['sqs_message_consumer_inject_mta_host']
SQS_MESSAGE_PROCESSOR_DIR               = node['xgemail']['sqs_message_processor_dir']
XGEMAIL_BUCKET_NAME                     = node['xgemail']['xgemail_bucket_name']
XGEMAIL_SNS_SQS_URL                     = node['xgemail']['xgemail_sns_sqs_url']
MAIL_PIC_API_RESPONSE_TIMEOUT           = node['xgemail']['mail_pic_apis_response_timeout_seconds']
MAIL_PIC_API_AUTH                       = node['xgemail']['mail_pic_api_auth']
MESSAGE_HISTORY_DELIVERY_STATUS_SNS_TOPIC_ARN = node['xgemail']['msg_history_status_sns_arn']
NODE_IP                                 = node['ipaddress']
POLICY_BUCKET_NAME                      = node['xgemail']['xgemail_policy_bucket_name']
TRANSPORT_CONFIG_PATH                   = XGEMAIL_FILES_DIR + '/config/transport-route-config.json'
E2E_LATENCY_TELEMETRY_DELIVERY_STREAM   =  "tf-e2e-latency-telemetry-#{AWS_REGION}-#{ACCOUNT}-firehose"
MH_MAIL_INFO_STORAGE_DIR                = node['xgemail']['mh_mail_info_storage_dir']
MSG_HISTORY_V2_BUCKET                   = node['xgemail']['msg_history_v2_bucket_name']

if NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'internet-delivery' || NODE_TYPE == 'mf-inbound-delivery' ||  NODE_TYPE == 'mf-outbound-delivery'
  #m5a.large 2vCPU / 8 GB.
  DEFAULT_NUMBER_OF_CONSUMER_THREADS = 3
else
  #c5a.large 2vCPU /4 GB.
  DEFAULT_NUMBER_OF_CONSUMER_THREADS = 3
end

THREAD_COUNT_CONFIG_KEY                 = 'config/delivery/multi.thread.count.' + NODE_TYPE

if ACCOUNT == 'sandbox'
  XGEMAIL_PIC_FQDN = 'mail-service:8080'
else
  if ACCOUNT_NAME == 'legacy'
    XGEMAIL_PIC_FQDN = "mail-#{STATION_VPC_NAME.downcase}-#{AWS_REGION}.#{ACCOUNT}.hydra.sophos.com"
  else
    XGEMAIL_PIC_FQDN = "mail.#{PARENT_ACCOUNT_NAME}.ctr.sophos.com"
  end
end

include_recipe 'sophos-cloud-xgemail::setup_xgemail_sqs_message_processors_structure'

CONSUMER_SCRIPT = 'xgemail_sqs_message_consumer.py'
CONSUMER_SERVICE_NAME = node['xgemail']['sqs_message_consumer_service_name']

CONSUMER_SCRIPT_PATH = "#{SQS_MESSAGE_PROCESSOR_DIR}/#{CONSUMER_SCRIPT}"

SERVICE_USER = node['xgemail']['sqs_message_processor_user']

# TODO : We shouldn't need sqsconsumer on any XDelivery or encryption submit right?
# Configs use by sqsmsgconsumer
if NODE_TYPE == 'customer-delivery' or NODE_TYPE == 'xdelivery' or NODE_TYPE == 'encryption-submit' or NODE_TYPE == 'mf-inbound-delivery' or NODE_TYPE == 'mf-inbound-xdelivery'
  MESSAGE_DIRECTION = 'INBOUND'
elsif NODE_TYPE == 'internet-delivery' or NODE_TYPE == 'internet-xdelivery' or
       NODE_TYPE == 'encryption-delivery' or NODE_TYPE == 'risky-delivery' or
       NODE_TYPE == 'risky-xdelivery' or NODE_TYPE == 'warmup-delivery' or
       NODE_TYPE == 'warmup-xdelivery' or NODE_TYPE == 'beta-delivery' or
       NODE_TYPE == 'beta-xdelivery' or NODE_TYPE == 'delta-delivery' or
       NODE_TYPE == 'delta-xdelivery' or NODE_TYPE == 'mf-outbound-delivery' or
       NODE_TYPE == 'mf-outbound-xdelivery'
  MESSAGE_DIRECTION = 'OUTBOUND'
else
  raise "Unsupported node type to setup sqsmsgproducer [#{NODE_TYPE}]"
end

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
    :xgemail_pic_fqdn => XGEMAIL_PIC_FQDN,
    :mail_pic_api_response_timeout => MAIL_PIC_API_RESPONSE_TIMEOUT,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR,
    :mail_pic_api_auth => MAIL_PIC_API_AUTH,
    :connections_bucket => CONNECTIONS_BUCKET,
    :message_direction => MESSAGE_DIRECTION,
    :message_history_status_sns_topic_arn => MESSAGE_HISTORY_DELIVERY_STATUS_SNS_TOPIC_ARN,
    :e2e_latency_telemetry_delivery_stream => E2E_LATENCY_TELEMETRY_DELIVERY_STREAM,
    :node_type => NODE_TYPE,
    :node_ip => NODE_IP,
    :account => ACCOUNT,
    :policy_bucket => POLICY_BUCKET_NAME,
    :transport_config_path => TRANSPORT_CONFIG_PATH,
    :mh_mail_info_storage_dir => MH_MAIL_INFO_STORAGE_DIR,
    :msg_history_v2_bucket_name => MSG_HISTORY_V2_BUCKET,
    :default_number_of_consumer_threads => DEFAULT_NUMBER_OF_CONSUMER_THREADS,
    :consumer_thread_count_key => THREAD_COUNT_CONFIG_KEY
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

service 'xgemail-sqs-consumer' do
  service_name CONSUMER_SERVICE_NAME
  init_command "/etc/init.d/#{CONSUMER_SERVICE_NAME}"
  supports :restart => true, :start => true, :stop => true, :reload => true
  subscribes :enable, 'template[xgemail-sqs-consumer]', :immediately
end
