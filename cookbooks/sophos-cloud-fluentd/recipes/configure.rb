#
# Cookbook Name:: sophos-cloud-fluentd
# Recipe:: configure
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures fluentd (td-agent)
#

ACCOUNT                       = node['sophos_cloud']['environment']
CONF_DIR                      = node['fluentd']['conf_dir']
INSTANCE_ID                   = node['ec2']['instance_id']
MAIN_DIR                      = node['fluentd']['main_dir']
NODE_TYPE                     = node['xgemail']['cluster_type']
PATTERNS_DIR                  = node['fluentd']['patterns_dir']
REGION                        = node['sophos_cloud']['region']
MSG_STATS_REJECT_SNS_TOPIC    = node['xgemail']['msg_statistics_rejection_sns_topic']
DELIVERY_STATUS_SNS_TOPIC     = node['xgemail']['msg_history_status_sns_topic']
SERVER_IP                     = node['ipaddress']
MAILLOG_FILTER_PATTERNS       = "(\\.#{REGION}\\.compute\\.internal|table\\shash:|sm-msp-queue|:\\sstatistics:\\s)"

# Configs
if NODE_TYPE == 'customer-delivery'
  SERVER_TYPE           = 'CUSTOMER_DELIVERY'
  SERVER_TYPE_XDELIVERY = 'CUSTOMER_XDELIVERY'
  DIRECTION             = 'INBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'xdelivery'
  SERVER_TYPE           = 'CUSTOMER_XDELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'INBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'internet-xdelivery'
  SERVER_TYPE           = 'INTERNET_XDELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'internet-delivery'
  SERVER_TYPE_XDELIVERY = 'INTERNET_XDELIVERY'
  SERVER_TYPE           = 'INTERNET_DELIVERY'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'encryption-delivery'
  SERVER_TYPE           = 'ENCRYPTION_DELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
else
  SERVER_TYPE           = 'UNKNOWN'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'UNKNOWN'
  NON_DELIVERY_DSN      = 'UNKNOWN'
end

# All instances - Start Order: 10
template 'fluentd-source-maillog' do
  path "#{CONF_DIR}/10-source-maillog.conf"
  source 'fluentd-source-maillog.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
end

# internet-submit and customer-submit - Start Order: 10
template 'fluentd-source-jilter' do
  path "#{CONF_DIR}/10-source-jilter.conf"
  source 'fluentd-source-jilter.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
      :application_name => NODE_TYPE
  )
  only_if { NODE_TYPE == 'internet-submit' || NODE_TYPE == 'customer-submit' || NODE_TYPE == 'encryption-submit' }
end

# All instances except extended delivery - Start Order: 10
template 'fluentd-source-lifecycle' do
  path "#{CONF_DIR}/10-source-lifecycle.conf"
  source 'fluentd-source-lifecycle.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE
  )
  not_if { NODE_TYPE == 'xdelivery' || NODE_TYPE == 'internet-xdelivery' }
end

# internet-delivery - Start Order: 10
 template 'fluentd-source-messagebouncer' do
   path "#{CONF_DIR}/10-source-messagebouncer.conf"
   source 'fluentd-source-messagebouncer.conf.erb'
   mode '0644'
   owner 'root'
   group 'root'
   variables(
     :application_name => NODE_TYPE
   )
   only_if { NODE_TYPE == 'internet-delivery' }
 end

# internet-submit - Start Order: 10
template 'fluentd-source-multi-policy' do
  path "#{CONF_DIR}/10-source-multi-policy.conf"
  source 'fluentd-source-multi-policy.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE
  )
  only_if { NODE_TYPE == 'internet-submit' || NODE_TYPE == 'encryption-submit' }
end

# internet-submit and customer-submit - Start Order: 10
template 'fluentd-source-policy' do
  path "#{CONF_DIR}/10-source-policy.conf"
  source 'fluentd-source-policy.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE
  )
  only_if { NODE_TYPE == 'internet-submit' || NODE_TYPE == 'customer-submit'|| NODE_TYPE == 'encryption-submit' }
end

# All delivery instances - Start Order: 10
template 'fluentd-source-sqsmsgconsumer' do
  path "#{CONF_DIR}/10-source-sqsmsgconsumer.conf"
  source 'fluentd-source-sqsmsgconsumer.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE
  )
  only_if { NODE_TYPE == 'customer-delivery' || NODE_TYPE == 'internet-delivery'|| NODE_TYPE == 'encryption-delivery' }
end

# internet-submit and customer-submit - Start Order: 10
template '/etc/td-agent.d/10-source-sqsmsgproducer.conf' do
  source 'fluentd-source-sqsmsgproducer.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE
  )
  only_if { NODE_TYPE == 'internet-submit' || NODE_TYPE == 'customer-submit'|| NODE_TYPE == 'encryption-submit' }
end

# All instances - Start Order: 10
template 'fluentd-source-monit' do
  path "#{CONF_DIR}/10-source-monit.conf"
  source 'fluentd-source-monit.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE
  )
end

# All instances except internet-submit  - Start Order: 20
template 'fluentd-match-maillog' do
  path "#{CONF_DIR}/20-match-maillog.conf"
  source 'fluentd-match-maillog.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :maillog_filter_patterns => MAILLOG_FILTER_PATTERNS,
    :region => REGION
  )
  only_if { NODE_TYPE == 'customer-submit' }
end

# All instances - Start Order: 50
template 'fluentd-filter-maillog' do
  path "#{CONF_DIR}/50-filter-maillog.conf"
  source 'fluentd-filter-maillog.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :patterns_dir => PATTERNS_DIR
  )
end

# Only internet-submit  - Start Order: 60
template 'fluentd-match-msg-stats-reject' do
  path "#{CONF_DIR}/60-match-msg-stats-reject.conf"
  source 'fluentd-match-msg-stats-reject.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :maillog_filter_patterns => MAILLOG_FILTER_PATTERNS,
    :region => REGION
  )
  only_if { NODE_TYPE == 'internet-submit' || NODE_TYPE == 'encryption-submit' }
end

#  - Start Order: 65
template 'fluentd-match-msg-delivery' do
  path "#{CONF_DIR}/65-match-msg-delivery.conf"
  source 'fluentd-match-msg-delivery.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :maillog_filter_patterns => MAILLOG_FILTER_PATTERNS,
    :region => REGION
  )
 only_if {
            NODE_TYPE == 'customer-delivery' ||
            NODE_TYPE == 'xdelivery' ||
            NODE_TYPE == 'internet-delivery' ||
            NODE_TYPE == 'internet-xdelivery' ||
            NODE_TYPE == 'encryption-delivery'
         }

end

#  Start Order: 70
template 'fluentd-filter-msg-delivery' do
  path "#{CONF_DIR}/70-filter-msg-delivery.conf"
  source 'fluentd-filter-msg-delivery.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if {
            NODE_TYPE == 'customer-delivery' ||
            NODE_TYPE == 'xdelivery' ||
            NODE_TYPE == 'internet-delivery' ||
            NODE_TYPE == 'internet-xdelivery' ||
            NODE_TYPE == 'encryption-delivery'
          }
  end

# Only internet-submit  - Start Order: 70
template 'fluentd-filter-msg-stats-reject' do
  path "#{CONF_DIR}/70-filter-msg-stats-reject.conf"
  source 'fluentd-filter-msg-stats-reject.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if { NODE_TYPE == 'internet-submit' || NODE_TYPE == 'encryption-submit' }
end

# All instances - Start Order: 70
template 'fluentd-filter-transform' do
  path "#{CONF_DIR}/70-filter-transform.conf"
  source 'fluentd-filter-transform.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :account => ACCOUNT,
    :application_name => NODE_TYPE,
    :instance_id => INSTANCE_ID,
    :region => REGION
  )
end

# Start Order: 75
template 'fluentd-filter-transform-msg-delivery' do
  path "#{CONF_DIR}/75-filter-transform-msg-delivery.conf"
  source 'fluentd-filter-transform-msg-delivery.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :server_type => SERVER_TYPE,
    :server_ip => SERVER_IP,
    :server_type_xdelivery => SERVER_TYPE_XDELIVERY,
    :direction => DIRECTION,
    :non_delivery_dsn => NON_DELIVERY_DSN
  )
 only_if {
            NODE_TYPE == 'customer-delivery' ||
            NODE_TYPE == 'xdelivery' ||
            NODE_TYPE == 'internet-delivery' ||
            NODE_TYPE == 'internet-xdelivery' ||
            NODE_TYPE == 'encryption-delivery'
      }
end

# Message delivery status on all delivery and x delivery servers
template 'fluentd-match-sns-msg-delivery' do
  path "#{CONF_DIR}/97-match-sns-msg-delivery.conf"
  source 'fluentd-match-sns-msg-delivery.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :main_dir => MAIN_DIR,
    :region => REGION,
    :sns_topic => DELIVERY_STATUS_SNS_TOPIC
  )
 only_if {
            NODE_TYPE == 'customer-delivery' ||
            NODE_TYPE == 'xdelivery' ||
            NODE_TYPE == 'internet-delivery' ||
            NODE_TYPE == 'internet-xdelivery' ||
            NODE_TYPE == 'encryption-delivery'
         }
end



# All instances - Start Order: 99
template 'fluentd-match-firehose' do
  path "#{CONF_DIR}/99-match-firehose.conf"
  source 'fluentd-match-firehose.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :region => REGION
  )
end

# Only internet-submit - Start Order: 99
template 'fluentd-match-sns-msg-stats-reject' do
  path "#{CONF_DIR}/99-match-sns-msg-stats-reject.conf"
  source 'fluentd-match-sns-msg-stats-reject.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :main_dir => MAIN_DIR,
    :region => REGION,
    :sns_topic => MSG_STATS_REJECT_SNS_TOPIC
  )
  only_if { NODE_TYPE == 'internet-submit' || NODE_TYPE == 'encryption-submit' }
end

cookbook_file 'postfix grok patterns' do
  path "#{PATTERNS_DIR}/postfix"
  source 'postfix.regexp'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'sns_msg_stats_reject_template' do
  path "#{MAIN_DIR}/sns_msg_stats_reject_template.erb"
  source 'fluentd_sns_msg_stats_reject_template.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'sns_msg_delivery_template' do
  path "#{MAIN_DIR}/sns_msg_delivery_template.erb"
  source 'fluentd_sns_msg_delivery_template.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'sns_msg_to_xdelivery_template' do
  path "#{MAIN_DIR}/sns_msg_to_xdelivery_template.erb"
  source 'fluentd_sns_msg_to_xdelivery_template.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

service 'td-agent' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [ :enable, :restart ]
end

