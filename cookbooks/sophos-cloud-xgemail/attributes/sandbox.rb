# Sandbox settings
sandbox_env = ENV['DEFAULT_ENVIRONMENT']
if sandbox_env == "sandbox"
  default['ipaddress']                   = '127.0.0.1'
  default['sophos_cloud']['region']      = ENV['DEFAULT_REGION']
  default['sophos_cloud']['environment'] = ENV['DEFAULT_ENVIRONMENT']
  default['xgemail']['cluster_type']     = ENV['INSTANCE_TYPE']

  default['xgemail']['xgemail_bucket_name']        = 'xgemail-submit'
  default['xgemail']['xgemail_queue_url']          = 'http://localstack-xgemail:4576/queue/Xgemail_Internet_Submit'
  default['xgemail']['msg_history_bucket_name']    = 'xgemail-msg-history'
  default['xgemail']['msg_history_queue_url']      = 'http://localstack-xgemail:4576/queue/Xgemail_MessageHistoryEvent_Delivery'
  default['xgemail']['xgemail_policy_bucket_name'] = 'xgemail-policy'


  default['xgemail']['sxl_dbl']          = 'fake-domain.com'
  default['xgemail']['sxl_rbl']          = 'fake-domain.com'
end