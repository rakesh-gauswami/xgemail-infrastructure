#
# Cookbook Name: sophos-cloud-xgemail
# Attribute: sandbox
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures customer submit postfix instance
#
#
# Sandbox settings
ENVIRONMENT = ENV['DEFAULT_ENVIRONMENT']
INSTANCE_TYPE = ENV['INSTANCE_TYPE']

if ENVIRONMENT == "sandbox"
  default['sophos_cloud']['region']      = ENV['DEFAULT_REGION']

  # TODO: context and account variables should be removed in favor of  environment
  default['sophos_cloud']['environment'] = ENV['DEFAULT_ENVIRONMENT']
  default['sophos_cloud']['context']     = ENV['DEFAULT_ENVIRONMENT']
  default['sophos_cloud']['account']     = ENV['DEFAULT_ENVIRONMENT']

  default['xgemail']['cluster_type']     = ENV['INSTANCE_TYPE']

  default['xgemail']['direction']        = ENV['DIRECTION']
  default['xgemail']['application']      = ENV['APPLICATION']

  default['xgemail']['msg_history_bucket_name']    = 'xgemail-msg-history'
  default['xgemail']['msg_history_ms_bucket_name']    = 'xgemail-msg-hist-ms'
  default['xgemail']['msg_history_queue_url']      = 'http://localstack:4576/queue/sandbox-Xgemail_MessageHistoryEvent_Delivery'
  default['xgemail']['xgemail_policy_bucket_name'] = 'sandbox-cloudemail-xgemail-policy'
  default['xgemail']['mail_pic_api_auth']          = 'xgemail-local-mail'
  default['xgemail']['msg_history_status_sns_arn'] = 'arn:aws:sns:us-east-1:123456789012:sandbox-xgemail-msg-history-delivery-status-SNS'
  default['sophos_cloud']['connections']           = 'cloud-sandbox-connections'
  default['xgemail']['msg_history_events_topic_arn']= 'arn:aws:sns:us-east-1:000000000000:sandbox-xgemail-msg-history-events-SNS'
  default['xgemail']['xgemail_policy_arn']         = 'arn:aws:sns:us-east-1:000000000000:sandbox-xgemail-policy-SNS'

  default['xgemail']['sxl_dbl']                    = 'fake-domain.com'
  default['xgemail']['sxl_rbl']                    = 'fake-domain.com'
  default['xgemail']['xgemail_active_profile']     = 'sandbox'
  default['xgemail']['launch_darkly_sandbox']      = 'sdk-00000000-0000-0000-0000-000000000000'
  default['xgemail']['station_vpc_name']           = 'pic'

  if INSTANCE_TYPE == "internet-submit" || INSTANCE_TYPE == "customer-delivery" || INSTANCE_TYPE == "mf-inbound-submit" || INSTANCE_TYPE == "mf-inbound-delivery"
    default['xgemail']['xgemail_bucket_name']           = 'sandbox-cloudemail-xgemail-submit'
    default['xgemail']['xgemail_scan_events_topic_arn'] = 'arn:aws:sns:us-east-1:000000000000:sandbox-xgemail-scan-events-SNS'
    default['xgemail']['xgemail_queue_url']             = 'http://localstack:4576/queue/sandbox-Xgemail_Internet_Submit'
    default['xgemail']['xgemail_service_queue_url']     = 'http://localstack:4576/queue/sandbox-Internet_Submit_Service_Queue'
    default['xgemail']['xgemail_sns_sqs_url']           = 'http://localstack:4576/queue/sandbox-Xgemail_Customer_Delivery_SNS_Listener'
  end

  if INSTANCE_TYPE == "customer-submit" || INSTANCE_TYPE == "internet-delivery"
    default['ec2']['instance_id'] = ENV['INSTANCE_ID']
    default['xgemail']['xgemail_bucket_name']    = 'xgemail-cust-submit'
    default['xgemail']['xgemail_queue_url']      = 'http://localstack:4576/queue/sandbox-Xgemail_Customer_Submit'
    default['xgemail']['xgemail_sns_sqs_url']    = 'http://localstack:4576/queue/sandbox-Xgemail_Internet_Delivery_SNS_Listener'
    default['xgemail']['msg_notifier_queue_url'] = 'http://localstack:4576/queue/sandbox-Xgemail_Notifier_Request'
  end

  if INSTANCE_TYPE == "mf-outbound-submit" || INSTANCE_TYPE == "mf-outbound-delivery"
    default['ec2']['instance_id'] = ENV['INSTANCE_ID']
    default['xgemail']['xgemail_bucket_name']    = 'xgemail-mf-outbound-submit'
    default['xgemail']['xgemail_queue_url']      = 'http://localstack:4576/queue/sandbox-Xgemail_Mf_Outbound_Submit'
    default['xgemail']['xgemail_sns_sqs_url']    = 'http://localstack:4576/queue/sandbox-Xgemail_Mf_Outbound_Delivery_SNS_Listener'
    default['xgemail']['msg_notifier_queue_url'] = 'http://localstack:4576/queue/sandbox-Xgemail_Notifier_Request'
  end

  if INSTANCE_TYPE == "jilter-inbound"
    default['xgemail']['xgemail_bucket_name'] = ""
  elsif INSTANCE_TYPE == "jilter-outbound"
    default['xgemail']['xgemail_bucket_name'] = "xgemail-cust-submit"
  end

  if INSTANCE_TYPE == "jilter-inbound" || INSTANCE_TYPE == "jilter-outbound"
    default['xgemail']['jilter_version'] = ENV['JILTER_VERSION']
    default['sophos_cloud']['thirdparty']  = '//cloud-sandbox-3rdparty'
    default['xgemail']['postfix_instance_data']['jilter-outbound'] =
      {
        :instance_name => 'jilter-outbound'
      }
    default['xgemail']['postfix_instance_data']['jilter-inbound'] =
          {
            :instance_name => 'jilter-inbound'
          }
  end
  default['sandbox']['mail_transport_entry']     = '* smtp:mailcatcher:1025'
  default['sandbox']['mail_relay_domain']        = 'sophos.com OK'
  default['sandbox']['mail_recipient_access']    = 'sophos.com OK'
end
