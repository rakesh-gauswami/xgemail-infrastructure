#
# Cookbook Name: sophos-cloud-xgemail
# Attribute: sandbox
#
# Copyright 2018, Sophos
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
    default['sophos_cloud']['environment'] = ENV['DEFAULT_ENVIRONMENT']
    default['xgemail']['cluster_type']     = ENV['INSTANCE_TYPE']

    default['xgemail']['xgemail_bucket_name']        = 'xgemail-submit'
    default['xgemail']['xgemail_queue_url']          = 'http://localstack-xgemail:4576/queue/Xgemail_Internet_Submit'
    default['xgemail']['msg_history_bucket_name']    = 'xgemail-msg-history'
    default['xgemail']['msg_history_queue_url']      = 'http://localstack-xgemail:4576/queue/Xgemail_MessageHistoryEvent_Delivery'
    default['xgemail']['xgemail_policy_bucket_name'] = 'xgemail-policy'

    default['xgemail']['xgemail_sns_sqs_url']        = 'http://localstack-xgemail:4576/queue/Xgemail_Customer_Delivery_SNS_Listener'
    default['xgemail']['mail_pic_api_auth']          = 'xgemail-us-east-2-mail'
    default['xgemail']['msg_history_status_sns_arn'] = 'arn:aws:sns:us-east-2:xgemail-msg-history-delivery-status-SNS'
    default['sophos_cloud']['connections']           = 'cloud-sandbox-connections'

    default['xgemail']['sxl_dbl']          = 'fake-domain.com'
    default['xgemail']['sxl_rbl']          = 'fake-domain.com'

    if INSTANCE_TYPE == "customer-submit"
        default['ec2']['instance_id']          = ENV['INSTANCE_ID']
    end
end
