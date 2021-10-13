#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_xgemail_mf_inbound_sqs_message_producer
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure submit email handler for xgemail
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

SMTPD_PORT = INSTANCE_DATA[:port]
raise "Invalid smtpd port for node type [#{NODE_TYPE}]" if SMTPD_PORT.nil?

include_recipe 'sophos-cloud-xgemail::setup_xgemail_mf_inbound_sqs_message_processors_structure'

AWS_REGION                                    = node['sophos_cloud']['region']
MESSAGEPROCESSOR_USER                         = node['xgemail']['sqs_message_processor_user']
NODE_IP                                       = node['ipaddress']
PRODUCER_SCRIPT                               = 'xgemail.sqs.message.producer.py'
S3_ENCRYPTION_ALGORITHM                       = node['xgemail']['s3_encryption_algorithm']
SQS_MESSAGE_PRODUCER_BUFFER_SIZE              = node['xgemail']['sqs_message_producer_buffer_size']
SQS_MESSAGE_PROCESSOR_DIR                     = node['xgemail']['sqs_message_processor_dir']
SQS_MESSAGE_PRODUCER_EMAIL_ROOT_DIR           = node['xgemail']['sqs_message_producer_email_root_dir']
SQS_MESSAGE_PRODUCER_TEMP_FAILURE_CODE        = node['xgemail']['temp_failure_code']
SQS_MESSAGE_PRODUCER_PROCESS_TIMEOUT_SECONDS  = node['xgemail']['sqs_message_producer_process_timeout_seconds']
SQS_MESSAGE_PRODUCER_TTL_IN_DAYS              = node['xgemail']['sqs_message_producer_ttl_in_days']
SUBMIT_DESTINATION_CONCUR_LIMIT               = node['xgemail']['submit_destination_concurrency_limit']
XGEMAIL_UTILS_DIR                             = node['xgemail']['xgemail_utils_files_dir']
PRODUCER_SCRIPT_PATH                          = "#{SQS_MESSAGE_PROCESSOR_DIR}/#{PRODUCER_SCRIPT}"
XGEMAIL_BUCKET_NAME                           = node['xgemail']['xgemail_bucket_name']
XGEMAIL_QUEUE_URL                             = node['xgemail']['xgemail_queue_url']
XGEMAIL_SERVICE_QUEUE_URL                     = node['xgemail']['xgemail_service_queue_url']
XGEMAIL_MESSAGE_HISTORY_BUCKET_NAME           = node['xgemail']['msg_history_bucket_name']
XGEMAIL_MESSAGE_HISTORY_MS_BUCKET_NAME        = node['xgemail']['msg_history_ms_bucket_name']
XGEMAIL_POLICY_S3_BUCKET_NAME                 = node['xgemail']['xgemail_policy_bucket_name']
POLICY_STORAGE_PATH                           = node['xgemail']['policy_efs_mount_dir']
XGEMAIL_SCAN_EVENTS_TOPIC_ARN                 = node['xgemail']['xgemail_scan_events_topic_arn']
XGEMAIL_MESSAGE_HISTORY_EVENTS_TOPIC_ARN      = node['xgemail']['xgemail_msg_history_events_topic_arn']
MSG_HISTORY_V2_BUCKET                         = node['xgemail']['msg_history_v2_bucket_name']
MSG_HISTORY_EVENT_DIR                         = node['xgemail']['mh_event_storage_dir']
MSG_HISTORY_EVENT_PROCESSOR_PORT              = node['xgemail']['mh_event_processor_port']

# TODO Once we retire the old submit instances this logic needs to be removed
#constants to use
SUBMIT = 'submit'
MF_INBOUND_SUBMIT = 'mf-inbound-submit'

# Configs use by sqsmsgproducer
if NODE_TYPE == MF_INBOUND_SUBMIT
  XGEMAIL_SUBMIT_TYPE = 'MF_INBOUND'
else
  raise "Unsupported node type to setup sqsmsgproducer [#{NODE_TYPE}]"
end

template PRODUCER_SCRIPT_PATH do
  source "#{PRODUCER_SCRIPT}.erb"
  mode "0750"
  owner MESSAGEPROCESSOR_USER
  group MESSAGEPROCESSOR_USER
  variables(
      :xgemail_submit_type => XGEMAIL_SUBMIT_TYPE,
      :xgemail_utils_path => XGEMAIL_UTILS_DIR,
      :s3_encryption_algorithm => S3_ENCRYPTION_ALGORITHM,
      :sns_scan_events_sns_topic_arn => XGEMAIL_SCAN_EVENTS_TOPIC_ARN,
      :sns_msg_history_events_sns_topic_arn => XGEMAIL_MESSAGE_HISTORY_EVENTS_TOPIC_ARN,
      :sqs_msg_producer_aws_region => AWS_REGION,
      :sqs_msg_producer_buffer_size => SQS_MESSAGE_PRODUCER_BUFFER_SIZE,
      :sqs_msg_producer_email_root_dir => SQS_MESSAGE_PRODUCER_EMAIL_ROOT_DIR,
      :sqs_msg_producer_ex_temp_failure_code => SQS_MESSAGE_PRODUCER_TEMP_FAILURE_CODE,
      :sqs_msg_producer_msg_history_s3_bucket_name => XGEMAIL_MESSAGE_HISTORY_BUCKET_NAME,
      :sqs_msg_producer_msg_history_ms_s3_bucket_name => XGEMAIL_MESSAGE_HISTORY_MS_BUCKET_NAME,
      :sqs_msg_producer_policy_s3_bucket_name => XGEMAIL_POLICY_S3_BUCKET_NAME,
      :sqs_msg_producer_process_timeout_seconds => SQS_MESSAGE_PRODUCER_PROCESS_TIMEOUT_SECONDS,
      :sqs_msg_producer_s3_bucket_name => XGEMAIL_BUCKET_NAME,
      :sqs_msg_producer_service_sqs_url => XGEMAIL_SERVICE_QUEUE_URL,
      :sqs_msg_producer_sqs_url => XGEMAIL_QUEUE_URL,
      :sqs_msg_producer_submit_ip => NODE_IP,
      :sqs_msg_producer_ttl_in_days => SQS_MESSAGE_PRODUCER_TTL_IN_DAYS,
      :policy_storage_path => POLICY_STORAGE_PATH,
      :msg_history_v2_bucket_name => MSG_HISTORY_V2_BUCKET,
      :msg_history_event_dir => MSG_HISTORY_EVENT_DIR,
      :msg_history_event_processor_port => MSG_HISTORY_EVENT_PROCESSOR_PORT
  )
end

# Configure Postfix
# This master.cf configuration pipes information to message producer script
# Piped arguments are positional. "original_recipients" may resolve into
# multiple recipients so it's mandatory to pass them in last.

NULL_SENDER='XGEMAIL_NULL_SENDER'
SERVICE_NAME='sqsmsgproducer'
SERVICE_TYPE='unix'

PIPE_COMMAND='pipe ' +
  'flags=hqu ' +
  "null_sender=#{NULL_SENDER} " +
  "user=#{MESSAGEPROCESSOR_USER} " +
  "argv=#{PRODUCER_SCRIPT_PATH} " +
    "#{NULL_SENDER} " +
    '${sender} ' +
    '${client_address} ' +
    '${queue_id} ' +
    '${nexthop} ' +
    '${original_recipient}'

# Install new pipe service into master
[
  "#{SERVICE_NAME}/#{SERVICE_TYPE} = #{SERVICE_NAME} #{SERVICE_TYPE} - n n - #{SUBMIT_DESTINATION_CONCUR_LIMIT} #{PIPE_COMMAND}"
].each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf -M '#{cur}'" )
end

# Activate new service by postfix configs
if NODE_TYPE == MF_INBOUND_SUBMIT
  # Update transports to use new pipe service
  [
      "default_transport = #{SERVICE_NAME}",
      "relay_transport = #{SERVICE_NAME}",
      "#{SERVICE_NAME}_destination_concurrency_limit = #{SUBMIT_DESTINATION_CONCUR_LIMIT}",
      "#{SERVICE_NAME}_initial_destination_concurrency = #{SUBMIT_DESTINATION_CONCUR_LIMIT}"
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end

else
  raise "Unsupported node type to setup postfix config [#{NODE_TYPE}]"
end

# Add rsyslog config file to redirect sqsmsgproducer messages to its own log file.
file '/etc/rsyslog.d/00-xgemail-sqsmsgproducer.conf' do
  content "if $syslogtag == '[sqsmsgproducer]' then /var/log/xgemail/sqsmsgproducer.log\n& ~"
  mode '0600'
  owner 'root'
  group 'root'
end
