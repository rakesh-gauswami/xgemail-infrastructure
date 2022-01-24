#
# Cookbook Name:: sophos-cloud-fluentd
# Recipe:: configure
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures fluentd (td-agent)
#

ACCOUNT                          = node['sophos_cloud']['environment']
CONF_DIR                         = node['fluentd']['conf_dir']
INSTANCE_ID                      = node['ec2']['instance_id']
MAIN_DIR                         = node['fluentd']['main_dir']
NODE_TYPE                        = node['xgemail']['cluster_type']
PATTERNS_DIR                     = node['fluentd']['patterns_dir']
PLUGIN_DIR                       = node['fluentd']['plugin_dir']
SQS_DELIVERY_DELAY               = node['fluentd']['sqs_delivery_delay']
REGION                           = node['sophos_cloud']['region']
MSG_STATS_REJECT_SNS_TOPIC       = node['xgemail']['msg_statistics_rejection_sns_topic']
DELIVERY_STATUS_SQS              = node['xgemail']['msg_history_delivery_status_sqs']
DELIVERY_STATUS_SNS_TOPIC        = node['xgemail']['msg_history_status_sns_topic']
TELEMETRY_LOG_SQS                = node['xgemail']['telemetry_log_sqs']
SERVER_IP                        = node['ipaddress']
MAILLOG_FILTER_PATTERNS          = "(\\.#{REGION}\\.compute\\.internal|:\\sdisconnect\\sfrom\\s|\\swarning:\\shostname\\s|:\\sremoved\\s|table\\shash:|sm-msp-queue|:\\sstatistics:\\s)"
JILTER_FILTER_PATTERNS           = "(com\\.launchdarkly\\.client\\.LDClient|com\\.launchdarkly\\.client\\.LDUser)"
LIFECYCLE_FILTER_PATTERNS        = "(?!.*)"
MESSAGEBOUNCER_FILTER_PATTERNS   = "(?!.*)"
MULTIPOLICY_FILTER_PATTERNS      = "(?!.*)"
SQSMSGCONSUMER_FILTER_PATTERNS   = "(?!.*)"
SQSMSGPRODUCER_FILTER_PATTERNS   = "(?!.*)"
TRANSPORTUPDATER_FILTER_PATTERNS = "(?!.*)"
MH_MAIL_INFO_STORAGE_DIR         = node['xgemail']['mh_mail_info_storage_dir']

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
elsif NODE_TYPE == 'risky-delivery'
  SERVER_TYPE_XDELIVERY = 'RISKY_XDELIVERY'
  SERVER_TYPE           = 'RISKY_DELIVERY'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'encryption-delivery'
  SERVER_TYPE           = 'ENCRYPTION_DELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'risky-xdelivery'
  SERVER_TYPE           = 'RISKY_XDELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'warmup-delivery'
  SERVER_TYPE_XDELIVERY = 'WARMUP_XDELIVERY'
  SERVER_TYPE           = 'WARMUP_DELIVERY'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'warmup-xdelivery'
  SERVER_TYPE           = 'WARMUP_XDELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'beta-delivery'
  SERVER_TYPE_XDELIVERY = 'BETA_XDELIVERY'
  SERVER_TYPE           = 'BETA_DELIVERY'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'beta-xdelivery'
  SERVER_TYPE           = 'BETA_XDELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'delta-delivery'
  SERVER_TYPE_XDELIVERY = 'DELTA_XDELIVERY'
  SERVER_TYPE           = 'DELTA_DELIVERY'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'delta-xdelivery'
  SERVER_TYPE           = 'DELTA_XDELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'mf-inbound-delivery'
  SERVER_TYPE           = 'MF_INBOUND_DELIVERY'
  SERVER_TYPE_XDELIVERY = 'MF_INBOUND_XDELIVERY'
  DIRECTION             = 'INBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'mf-outbound-delivery'
  SERVER_TYPE           = 'MF_OUTBOUND_DELIVERY'
  SERVER_TYPE_XDELIVERY = 'MF_OUTBOUND_XDELIVERY'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'mf-inbound-xdelivery'
  SERVER_TYPE           = 'MF_INBOUND_DELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'INBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
elsif NODE_TYPE == 'mf-outbound-xdelivery'
  SERVER_TYPE           = 'MF_OUTBOUND_DELIVERY'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'OUTBOUND'
  NON_DELIVERY_DSN      = '5.4.7'
else
  SERVER_TYPE           = 'UNKNOWN'
  SERVER_TYPE_XDELIVERY = 'UNKNOWN'
  DIRECTION             = 'UNKNOWN'
  NON_DELIVERY_DSN      = 'UNKNOWN'
end

if NODE_TYPE == 'mf-inbound-submit'
    EMAIL_PRODUCT_TYPE = 'Mailflow'
else
    EMAIL_PRODUCT_TYPE = 'Gateway'
end

### Fluentd Source Configuration Files ###

# All instances - Start Order: 10
template 'fluentd-source-maillog' do
  path "#{CONF_DIR}/10-source-maillog.conf"
  source 'fluentd-source-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :log_name => 'maillog',
    :log_path => '/var/log/maillog'
  )
end

# Submit instances - Start Order: 10
template 'fluentd-source-jilter' do
  path "#{CONF_DIR}/10-source-jilter.conf"
  source 'fluentd-source-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :log_name => 'jilter',
    :log_path => '/var/log/xgemail/jilter.log'
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'customer-submit' ||
    NODE_TYPE == 'encryption-submit' ||
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'mf-inbound-submit' ||
    NODE_TYPE == 'mf-outbound-submit' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-xdelivery'||
    NODE_TYPE == 'encryption-delivery'
  }
end

# All instances except extended delivery - Start Order: 10
template 'fluentd-source-lifecycle' do
  path "#{CONF_DIR}/10-source-lifecycle.conf"
  source 'fluentd-source-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :log_name => 'lifecycle',
    :log_path => '/var/log/xgemail/lifecycle.log'
  )
  not_if {
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-xdelivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery'
  }
end

# internet-delivery - Start Order: 10
 template 'fluentd-source-messagebouncer' do
   path "#{CONF_DIR}/10-source-messagebouncer.conf"
   source 'fluentd-source-generic.conf.erb'
   mode '0644'
   owner 'root'
   group 'root'
   variables(
     :log_name => 'messagebouncer',
     :log_path => '/var/log/xgemail/messagebouncer.log'
   )
   only_if {
     NODE_TYPE == 'internet-delivery' ||
     NODE_TYPE == 'risky-delivery' ||
     NODE_TYPE == 'warmup-delivery' ||
     NODE_TYPE == 'beta-delivery' ||
     NODE_TYPE == 'delta-delivery' ||
     NODE_TYPE == 'mf-outbound-delivery'
   }
 end

# internet-submit - Start Order: 10
template 'fluentd-source-multi-policy' do
  path "#{CONF_DIR}/10-source-multi-policy.conf"
  source 'fluentd-source-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :log_name => 'multi-policy',
    :log_path => '/var/log/xgemail/multi-policy.log'
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'mf-inbound-submit'
  }
end

# All delivery instances - Start Order: 10
template 'fluentd-source-sqsmsgconsumer' do
  path "#{CONF_DIR}/10-source-sqsmsgconsumer.conf"
  source 'fluentd-source-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :log_name => 'sqsmsgconsumer',
    :log_path => '/var/log/xgemail/sqsmsgconsumer.log'
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'encryption-delivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'delta-delivery'
  }
end

# Customer delivery and xdelivery instances - Start Order: 10
template 'fluentd-source-transportupdater' do
  path "#{CONF_DIR}/10-source-transportupdater.conf"
  source 'fluentd-source-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :log_name => 'transportupdater',
    :log_path => '/var/log/xgemail/transportupdater.log'
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery'
  }
end

# Submit instances - Start Order: 10
template 'fluentd-source-sqsmsgproducer' do
  path "#{CONF_DIR}/10-source-sqsmsgproducer.conf"
  source 'fluentd-source-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :log_name => 'sqsmsgproducer',
    :log_path => '/var/log/xgemail/sqsmsgproducer.log'
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'customer-submit' ||
    NODE_TYPE == 'mf-inbound-submit' ||
    NODE_TYPE == 'mf-outbound-submit' ||
    NODE_TYPE == 'encryption-submit'
  }
end

# All instances - Start Order: 10
template 'fluentd-source-monit' do
  path "#{CONF_DIR}/10-source-monit.conf"
  source 'fluentd-source-monit.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
  )
end

### Fluentd Match Configuration Files ###

# customer-submit, encryption-submit, and encryption-delivery - Start Order: 20
template 'fluentd-match-maillog' do
  path "#{CONF_DIR}/20-match-maillog.conf"
  source 'fluentd-match-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'maillog',
    :filter_patterns => MAILLOG_FILTER_PATTERNS
  )
  only_if {
    NODE_TYPE == 'customer-submit' ||
    NODE_TYPE == 'mf-outbound-submit' ||
    NODE_TYPE == 'encryption-submit' ||
    NODE_TYPE == 'encryption-delivery'
  }
end

# Submit instances - Start Order: 20
template 'fluentd-match-jilter' do
  path "#{CONF_DIR}/20-match-jilter.conf"
  source 'fluentd-match-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'jilter',
    :filter_patterns => JILTER_FILTER_PATTERNS
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'customer-submit' ||
    NODE_TYPE == 'encryption-submit' ||
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'mf-inbound-submit' ||
    NODE_TYPE == 'mf-outbound-submit' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-xdelivery' ||
    NODE_TYPE == 'encryption-delivery'
  }
end

# All instances except extended delivery - Start Order: 20
template 'fluentd-match-lifecycle' do
  path "#{CONF_DIR}/20-match-lifecycle.conf"
  source 'fluentd-match-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'lifecycle',
    :filter_patterns => LIFECYCLE_FILTER_PATTERNS
  )
  not_if {
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-xdelivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery'
  }
end

# internet-delivery - Start Order: 20
 template 'fluentd-match-messagebouncer' do
   path "#{CONF_DIR}/20-match-messagebouncer.conf"
   source 'fluentd-match-generic.conf.erb'
   mode '0644'
   owner 'root'
   group 'root'
   variables(
    :application_name => NODE_TYPE,
    :log_name => 'messagebouncer',
    :filter_patterns => MESSAGEBOUNCER_FILTER_PATTERNS
  )
   only_if {
     NODE_TYPE == 'internet-delivery' ||
     NODE_TYPE == 'mf-outbound-delivery' ||
     NODE_TYPE == 'risky-delivery' ||
     NODE_TYPE == 'warmup-delivery' ||
     NODE_TYPE == 'beta-delivery'||
     NODE_TYPE == 'delta-delivery'
   }
 end

# internet-submit - Start Order: 20
template 'fluentd-match-multi-policy' do
  path "#{CONF_DIR}/20-match-multi-policy.conf"
  source 'fluentd-match-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'multi-policy',
    :filter_patterns => MULTIPOLICY_FILTER_PATTERNS
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'mf-inbound-submit'
  }
end

# Submit instances - Start Order: 20
template 'fluentd-match-sqsmsgproducer' do
  path "#{CONF_DIR}/20-match-sqsmsgproducer.conf"
  source 'fluentd-match-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'sqsmsgproducer',
    :filter_patterns => SQSMSGPRODUCER_FILTER_PATTERNS
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'customer-submit'||
    NODE_TYPE == 'encryption-submit' ||
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'mf-inbound-submit' ||
    NODE_TYPE == 'mf-outbound-submit' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-xdelivery'||
    NODE_TYPE == 'encryption-delivery'
  }
end

# All delivery instances - Start Order: 20
template 'fluentd-match-sqsmsgconsumer' do
  path "#{CONF_DIR}/20-match-sqsmsgconsumer.conf"
  source 'fluentd-match-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'sqsmsgconsumer',
    :filter_patterns => SQSMSGCONSUMER_FILTER_PATTERNS
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'encryption-delivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'delta-delivery'
  }
end

template 'fluentd-match-transportupdater' do
  path "#{CONF_DIR}/20-match-transportupdater.conf"
  source 'fluentd-match-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'transportupdater',
    :filter_patterns => TRANSPORTUPDATER_FILTER_PATTERNS
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery'
  }
end

### Fluentd Filter Configuration Files ###

# All instances - Start Order: 50
template 'fluentd-filter-maillog' do
  path "#{CONF_DIR}/50-filter-maillog.conf"
  source 'fluentd-filter-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'maillog',
    :grok_pattern => 'MAILLOG',
    :reserve_data => 'true',
    :patterns_dir => PATTERNS_DIR
  )
end

# Submit instances - Start Order: 50
template 'fluentd-filter-jilter' do
  path "#{CONF_DIR}/50-filter-jilter.conf"
  source 'fluentd-filter-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'jilter',
    :grok_pattern => 'JILTER',
    :reserve_data => 'true',
    :patterns_dir => PATTERNS_DIR
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'customer-submit'||
    NODE_TYPE == 'mf-inbound-submit' ||
    NODE_TYPE == 'mf-outbound-submit' ||
    NODE_TYPE == 'encryption-submit'
  }
end

# All instances except extended delivery - Start Order: 50
template 'fluentd-filter-lifecycle' do
  path "#{CONF_DIR}/50-filter-lifecycle.conf"
  source 'fluentd-filter-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'lifecycle',
    :grok_pattern => 'LIFECYCLE',
    :reserve_data => 'true',
    :patterns_dir => PATTERNS_DIR
  )
  not_if {
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-xdelivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery'
  }
end

# internet-delivery - Start Order: 50
 template 'fluentd-filter-messagebouncer' do
   path "#{CONF_DIR}/50-filter-messagebouncer.conf"
   source 'fluentd-filter-generic.conf.erb'
   mode '0644'
   owner 'root'
   group 'root'
   variables(
    :application_name => NODE_TYPE,
    :log_name => 'messagebouncer',
    :grok_pattern => 'MESSAGEBOUNCER',
    :reserve_data => 'true',
    :patterns_dir => PATTERNS_DIR
  )
   only_if {
     NODE_TYPE == 'internet-delivery' ||
     NODE_TYPE == 'mf-outbound-delivery' ||
     NODE_TYPE == 'risky-delivery' ||
     NODE_TYPE == 'warmup-delivery' ||
     NODE_TYPE == 'beta-delivery'||
     NODE_TYPE == 'delta-delivery'
   }
 end

# internet-submit - Start Order: 50
template 'fluentd-filter-multi-policy' do
  path "#{CONF_DIR}/50-filter-multi-policy.conf"
  source 'fluentd-filter-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'multi-policy',
    :grok_pattern => 'MULTIPOLICY',
    :reserve_data => 'true',
    :patterns_dir => PATTERNS_DIR
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'mf-inbound-submit'
  }
end

# Submit instances - Start Order: 50
template 'fluentd-filter-sqsmsgproducer' do
  path "#{CONF_DIR}/50-filter-sqsmsgproducer.conf"
  source 'fluentd-filter-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'sqsmsgproducer',
    :grok_pattern => 'SQSMSGPRODUCER',
    :reserve_data => 'true',
    :patterns_dir => PATTERNS_DIR
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'customer-submit'||
    NODE_TYPE == 'mf-inbound-submit' ||
    NODE_TYPE == 'mf-outbound-submit' ||
    NODE_TYPE == 'encryption-submit'
  }
end

# All delivery instances - Start Order: 50
template 'fluentd-filter-sqsmsgconsumer' do
  path "#{CONF_DIR}/50-filter-sqsmsgconsumer.conf"
  source 'fluentd-filter-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'sqsmsgconsumer',
    :grok_pattern => 'SQSMSGCONSUMER',
    :reserve_data => 'true',
    :patterns_dir => PATTERNS_DIR
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'encryption-delivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'delta-delivery'
  }
end

template 'fluentd-filter-transportupdater' do
  path "#{CONF_DIR}/50-filter-transportupdater.conf"
  source 'fluentd-filter-generic.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :log_name => 'transportupdater',
    :grok_pattern => 'TRANSPORTUPDATER',
    :reserve_data => 'true',
    :patterns_dir => PATTERNS_DIR
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'xdelivery'
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery'
  }
end

### Fluentd Customized Configuration Files ###
#
# Only internet-submit  - Start Order: 60
template 'fluentd-match-postfix-maillog' do
  path "#{CONF_DIR}/60-match-postfix-maillog.conf"
  source 'fluentd-match-postfix-maillog.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :application_name => NODE_TYPE,
    :maillog_filter_patterns => MAILLOG_FILTER_PATTERNS,
    :region => REGION
  )
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'mf-inbound-submit'
  }
end

#  - Start Order: 60
template 'fluentd-match-msg-delivery' do
  path "#{CONF_DIR}/60-match-msg-delivery.conf"
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
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'delta-xdelivery'
  }
end

#  Start Order: 70
#  Remove this when we shift completely to SQS type match
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
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'delta-xdelivery'
  }
  end

# Only internet-submit  - Start Order: 70
template 'fluentd-filter-msg-stats-reject' do
  path "#{CONF_DIR}/70-filter-msg-stats-reject.conf"
  source 'fluentd-filter-msg-stats-reject.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'mf-inbound-submit'
  }
  variables(
    :email_product_type => EMAIL_PRODUCT_TYPE
  )
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

# Start Order: 70
template 'fluentd-filter-transform-sqs-telemetry-log' do
  path "#{CONF_DIR}/70-filter-transform-sqs-telemetry-log.conf"
  source 'fluentd-filter-transform-sqs-telemetry-log.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if {
      NODE_TYPE == 'internet-submit' ||
      NODE_TYPE == 'mf-inbound-submit'
    }
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
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'warmup-xdelivery'||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'delta-xdelivery'
  }
end

# Start Order: 77
template 'fluentd-filter-transform-sqs-msg' do
  path "#{CONF_DIR}/77-filter-transform-sqs-msg.conf"
  source 'fluentd-filter-transform-sqs-msg.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
      :main_dir => MAIN_DIR
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'warmup-xdelivery'||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'delta-xdelivery'
  }
end
# Start Order: 78
template 'fluentd-filter-transform-msg-history-v2' do
  path "#{CONF_DIR}/78-filter-transform-msg-history-v2.conf"
  source 'fluentd-filter-transform-msg-history-v2.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :server_type => SERVER_TYPE,
    :server_ip => SERVER_IP,
    :non_delivery_dsn => NON_DELIVERY_DSN,
    :mh_mail_info_storage_dir => MH_MAIL_INFO_STORAGE_DIR
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'warmup-xdelivery'||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'delta-xdelivery'
  }
end

# Message delivery status on all delivery and x delivery servers
# Remove this when we shift completely to SQS type match
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
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'delta-xdelivery'
  }
end

# Message delivery status on all delivery and x delivery servers
template 'fluentd-match-sqs-msg-delivery' do
  path "#{CONF_DIR}/97-match-sqs-msg-delivery.conf"
  source 'fluentd-match-sqs-msg-delivery.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
      :region => REGION,
      :sqs_delivery_delay => SQS_DELIVERY_DELAY,
      :delivery_status_queue => DELIVERY_STATUS_SQS
  )
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'warmup-xdelivery' ||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'delta-xdelivery'
  }
end
# Start Order: 98 - MHv2
template 'fluentd-match-http-output-msg-history-v2' do
  path "#{CONF_DIR}/98-match-http-output-msg-history-v2.conf"
  source 'fluentd-match-http-output-msg-history-v2.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  only_if {
    NODE_TYPE == 'customer-delivery' ||
    NODE_TYPE == 'xdelivery' ||
    NODE_TYPE == 'internet-delivery' ||
    NODE_TYPE == 'internet-xdelivery' ||
    NODE_TYPE == 'mf-inbound-delivery' ||
    NODE_TYPE == 'mf-outbound-delivery' ||
    NODE_TYPE == 'mf-inbound-xdelivery' ||
    NODE_TYPE == 'mf-outbound-xdelivery' ||
    NODE_TYPE == 'risky-delivery' ||
    NODE_TYPE == 'risky-xdelivery' ||
    NODE_TYPE == 'warmup-delivery' ||
    NODE_TYPE == 'warmup-xdelivery'||
    NODE_TYPE == 'beta-delivery' ||
    NODE_TYPE == 'beta-xdelivery' ||
    NODE_TYPE == 'delta-delivery' ||
    NODE_TYPE == 'delta-xdelivery'
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
  only_if {
    NODE_TYPE == 'internet-submit' ||
    NODE_TYPE == 'mf-inbound-submit'
  }
end

template 'fluentd-match-sqs-telemetry-log' do
  path "#{CONF_DIR}/99-match-sqs-telemetry-log.conf"
  source 'fluentd-match-sqs-telemetry-log.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
      :region => REGION,
      :telemetry_log_queue => TELEMETRY_LOG_SQS
  )
  only_if {
      NODE_TYPE == 'internet-submit' ||
      NODE_TYPE == 'mf-inbound-submit'
    }
end

cookbook_file 'maillog grok patterns' do
  path "#{PATTERNS_DIR}/maillog"
  source 'maillog.grok'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'jilter grok patterns' do
  path "#{PATTERNS_DIR}/jilter"
  source 'jilter.grok'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'lifecycle grok patterns' do
  path "#{PATTERNS_DIR}/lifecycle"
  source 'lifecycle.grok'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'messagebouncer grok patterns' do
  path "#{PATTERNS_DIR}/messagebouncer"
  source 'messagebouncer.grok'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'multi-policy grok patterns' do
  path "#{PATTERNS_DIR}/multi-policy"
  source 'multi-policy.grok'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'sqsmsgconsumer grok patterns' do
  path "#{PATTERNS_DIR}/sqsmsgconsumer"
  source 'sqsmsgconsumer.grok'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'transportupdater grok patterns' do
  path "#{PATTERNS_DIR}/transportupdater"
  source 'transportupdater.grok'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file 'sqsmsgproducer grok patterns' do
  path "#{PATTERNS_DIR}/sqsmsgproducer"
  source 'sqsmsgproducer.grok'
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

# Remove this when we shift completely to SQS type match
cookbook_file 'sns_msg_delivery_template' do
  path "#{MAIN_DIR}/sns_msg_delivery_template.erb"
  source 'fluentd_sns_msg_delivery_template.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

# Remove this when we shift completely to SQS type match
cookbook_file 'sns_msg_to_xdelivery_template' do
  path "#{MAIN_DIR}/sns_msg_to_xdelivery_template.erb"
  source 'fluentd_sns_msg_to_xdelivery_template.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

# fluentd plugin for mhv2 mail info file check
cookbook_file 'fluentd_plugin_msg_history_v2_mailinfo_filecheck' do
  path "#{PLUGIN_DIR}/filter_mhv2filecheck.rb"
  source 'fluentd_plugin_msg_history_v2_mailinfo_filecheck.rb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

service 'td-agent' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [ :enable, :restart ]
end
