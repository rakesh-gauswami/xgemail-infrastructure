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

    # TODO: context and account variables should be removed in favor of  environment
    default['sophos_cloud']['environment'] = ENV['DEFAULT_ENVIRONMENT']
    default['sophos_cloud']['context']     = ENV['DEFAULT_ENVIRONMENT']
    default['sophos_cloud']['account']     = ENV['DEFAULT_ENVIRONMENT']

    default['xgemail']['cluster_type']     = ENV['INSTANCE_TYPE']

    default['xgemail']['xgemail_bucket_name']        = 'xgemail-submit'
    default['xgemail']['xgemail_queue_url']          = 'http://localstack-xgemail:4576/queue/sandbox-Xgemail_Internet_Submit'
    default['xgemail']['msg_history_bucket_name']    = 'xgemail-msg-history'
    default['xgemail']['msg_history_queue_url']      = 'http://localstack-xgemail:4576/queue/sandbox-Xgemail_MessageHistoryEvent_Delivery'
    default['xgemail']['xgemail_policy_bucket_name'] = 'xgemail-policy'

    default['xgemail']['xgemail_sns_sqs_url']        = 'http://localstack-xgemail:4576/queue/sandbox-Xgemail_Customer_Delivery_SNS_Listener'
    default['xgemail']['mail_pic_api_auth']          = 'xgemail-local-mail'
    default['xgemail']['msg_history_status_sns_arn'] = 'arn:aws:sns:local:xgemail-msg-history-delivery-status-SNS'
    default['sophos_cloud']['connections']           = 'cloud-sandbox-connections'

    default['xgemail']['sxl_dbl']                    = 'fake-domain.com'
    default['xgemail']['sxl_rbl']                    = 'fake-domain.com'
    default['xgemail']['xgemail_active_profile']     = 'sandbox'
    default['xgemail']['station_vpc_name']           = 'pic'


    if INSTANCE_TYPE == "customer-submit"
        default['ec2']['instance_id'] = ENV['INSTANCE_ID']
    end

    default['sandbox']['mail_transport_entry']     = 'sophos.com mailcatcher:1025'
    default['sandbox']['mail_relay_domain']        = 'sophos.com OK'
    default['sandbox']['mail_recipient_access']    = 'sophos.com OK'
end
