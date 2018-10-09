#
# Cookbook Name:: sophos-cloud-xgemail
# Attribute:: default
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Instead of literal constants, the "client" cookbook code should use
# values from the special three-dimensional map 'node', e.g.
#
#   x = #{node[k0][k1]}
#
# The value of #{node[k1][k2]} will come from two places:
#
#   (1) (if exists) a proper setting taken from the 'attributes.json'
#       file residing in the "script_path" (see below).
#
#   (2) (if (1) does not exist) the value, for the same keys 'k0' and
#       'k1', taken from the three-dimensional map 'default'
#
# The following populates the 'default' map.  Do not put in anything
# here that cannot be a reasonable default for all systems where these
# cookbooks are running; e.g. do not add the name of the "next host".

# Sophos
default['sophos_cloud']['application']                  = '//cloud-applications/develop/core-services.war'
default['sophos_cloud']['configs']                      = '//cloud-dev-configs'
default['sophos_cloud']['connections']                  = '//cloud-dev-connections'
default['sophos_cloud']['environment']                  = 'dev'
default['sophos_cloud']['context']                      = 'dev'
#
default['sophos_cloud']['cookbooks']                    = '//cloud-dev-cookbooks/cookbooks.tar.gz'
default['sophos_cloud']['domain']                       = 'p0.d.hmr.sophos.com'
default['sophos_cloud']['local_cert_path']              = '/etc/ssl/certs'
default['sophos_cloud']['local_key_path']               = '/etc/ssl/private'
default['sophos_cloud']['script_path']                  = '/var/sophos/scripts'
default['sophos_cloud']['thirdparty']                   = '//cloud-dev-3rdparty'
default['sophos_cloud']['tmp']                          = '/tmp/sophos'


# XGEmail-specific settings
default['xgemail']['station_vpc_name'] = nil

XGEMAIL_FILES_DIR = '/opt/sophos/xgemail'
## Common files location
default['xgemail']['xgemail_files_dir'] = XGEMAIL_FILES_DIR

default['xgemail']['cert']              = 'xgemail'

# This is used on the 'processing' host only
## CYREN settings
default['xgemail']['ctasd_url'] = 'ftp.ctmail.com/ctasd/Release'
default['xgemail']['ctasd_package_version'] = '5.01.0006.4'
default['xgemail']['ctasd_license_key'] = '0001W000S0051K019G03'
default['xgemail']['ctasd_server_address'] = 'resolver%d.sophos.ctmail.com'
default['xgemail']['ctasd_daemon_stop_timeout'] = 5
default['xgemail']['ctasd_agent_stop_timeout'] = 5
default['xgemail']['ctasd_agent_oid'] = '1.3.6.1.4.1.9915.3'
default['xgemail']['ctasd_agent_have_snmp'] = 'YES'

## SAVi settings
default['xgemail']['savdid_savdi_url'] = 'https://downloads.sophos.com/sophos/products/full'
default['xgemail']['savdid_service_name'] = 'savdid'
default['xgemail']['savdid_dir'] = '/usr/local/savdi'
default['xgemail']['savdid_log_xgemail_dir'] = '/var/log/xgemail'
default['xgemail']['savdid_log_dir'] = '/var/log/xgemail/savdid'
default['xgemail']['savdid_sig_dir'] = '/usr/local/sav'
default['xgemail']['savdid_pid_file'] = '/var/run/savdid'
default['xgemail']['savdid_owner'] = 'root'
default['xgemail']['savdid_group'] = 'root'
default['xgemail']['savdid_send_timeout_in_sec'] = 3
default['xgemail']['savdid_receive_timeout_in_sec'] = 4
default['xgemail']['savdid_max_scan_data_size_in_bytes'] = 0
default['xgemail']['savdid_max_memory_size_in_bytes'] = 50000000
default['xgemail']['savdid_max_scan_time_in_sec'] = 7
default['xgemail']['savdid_max_request_time_in_sec'] = 10
default['xgemail']['savdid_username'] = 'SET05879'
default['xgemail']['savdid_password'] = 'h44d63sr'
default['xgemail']['savdid_library'] = 'savi'
default['xgemail']['savdid_savi_version'] = '2.3'
default['xgemail']['savdid_savdi_library'] = 'savdi'
default['xgemail']['savdid_version'] = '2.4'
default['xgemail']['savdid_cxmail_version'] = 'Cloud:Email:1.0.0'

# Jilter settings
default['xgemail']['libspfjni'] = '1.0.0-SNAPSHOT'
default['xgemail']['libspf2_version'] = '1.2.10-9'
default['xgemail']['jilter_user'] = 'jilter'
default['xgemail']['jilter_service_name'] = 'xgemail-jilter-service'
default['xgemail']['xgemail_active_profile'] = 'aws'

# DKIM specific
default['xgemail']['libdkimjni'] = '1.0.0-SNAPSHOT'
default['xgemail']['libopendkim_version'] = '2.11.0'

default['xgemail']['policy_efs_mount_dir'] = '/policy-storage'

## SAVi SXL Live Protection settings
default['xgemail']['savdid_sxl_pua_detection'] = 1
default['xgemail']['savdid_sxl_dns_res'] = '/etc/resolv.conf'
default['xgemail']['savdid_sxl_top_level_domain'] = 'rfl.sophosxl.net'
default['xgemail']['savdid_sxl_server_list'] = '000102030405060708'
default['xgemail']['savdid_sxl_hex_id_customer'] = '51726d45ec33aeb82d556e0f25e20296'
default['xgemail']['savdid_sxl_hex_id_machine'] = '51726d45ec33aeb82d556e0f25e11111'
default['xgemail']['savdid_sxl_live_protection_enabled'] = 1

## Domain blacklist settings
default['xgemail']['sxl_dbl'] = nil
# SXL returns different codes for domain reputation lookup. All of the following
# response codes are considered spam except 127.0.1.2:
#
#  - 127.0.1.1: SXL_URI (Contains a known spam URL (SXL lookup))
#  - 127.0.1.2: SXL_URI_NEW (Contains a recently registered domain name (SXL lookup))
#  - 127.0.1.3: SXL_URI_LAB (Contains a known spam URL (SXL lookup))
#  - 127.0.1.4: SXL_URI_SBC (Contains a known spam URL (SXL lookup))
#  - 127.0.1.5: SXL_URI_SHD (Contains a known spam URL (SXL lookup))
default['xgemail']['sxl_dbl_response_codes'] = "127.0.1.[1;3;4;5]"

# The third-party product VBSpam is allowed to use the Postfix XCLIENT
# extension in order to spoof the source IP of the messages its sending.
# More information can be found at
# https://wiki.sophos.net/display/NSG/VBSpam+Integration+into+Sophos+Email
default['xgemail']['smtpd_authorized_xclient_hosts'] = "81.136.243.94"

# Increase Postfix default process limit from default 100 to 200
default['xgemail']['postfix_default_process_limit'] = 200

## IP blacklist settings
default['xgemail']['sxl_rbl'] = nil

## SNS Topics
default['xgemail']['msg_statistics_rejection_sns_topic'] = "#{node['xgemail']['station_vpc_id']}-xgemail-msg-statistics-rejection-SNS"
default['xgemail']['msg_history_status_sns_topic'] = "#{node['xgemail']['station_vpc_id']}-xgemail-msg-history-delivery-status-SNS"

## Policy service/poller settings
default['xgemail']['sqs_policy_poller_max_number_of_messages'] = 10
default['xgemail']['sqs_policy_poller_wait_time_seconds'] = 20
default['xgemail']['sqs_policy_poller_visibility_timeout'] = '10'
default['xgemail']['sqs_policy_poller_message_retention_period'] = '172800'
default['xgemail']['sqs_policy_sqs_message_visibility_timeout'] = 300
default['xgemail']['sqs_policy_poller_service_name'] = 'xgemail-sqs-policy-poller'
default['xgemail']['sqs_multi_policy_poller_service_name'] = 'xgemail-sqs-multi-policy-poller'

## SQS Lifecycle Poller settings
default['xgemail']['sqs_lifecycle_poller_max_number_of_messages'] = 10
default['xgemail']['sqs_lifecycle_poller_visibility_timeout'] = '30'
default['xgemail']['sqs_lifecycle_poller_wait_time_seconds'] = 10
default['xgemail']['sqs_lifecycle_poller_message_retention_period'] = '3600'

## Policy and message processors utils
default['xgemail']['xgemail_utils_files_dir'] = "#{XGEMAIL_FILES_DIR}/utils"

default['xgemail']['temp_failure_code'] = 75

## SQS Message Processors settings
XGEMAIL_SQS_MESSAGE_PROCESSOR_DIR="#{XGEMAIL_FILES_DIR}/sqs-message-processor"
default['xgemail']['sqs_message_processor_dir'] = XGEMAIL_SQS_MESSAGE_PROCESSOR_DIR
default['xgemail']['sqs_message_processor_common_dir'] = "#{XGEMAIL_SQS_MESSAGE_PROCESSOR_DIR}/common"
default['xgemail']['sqs_message_processor_user'] = 'messageprocessor'

## SQS Message Producer settings
default['xgemail']['sqs_message_producer_ttl_in_days'] = 30
default['xgemail']['sqs_message_producer_email_root_dir'] = 'messages'
default['xgemail']['sqs_message_producer_buffer_size'] = 102400

# Postfix's command_time_limit is set to 1000 seconds by default, so make sure
# the timeout used here is less than that default
default['xgemail']['sqs_message_producer_process_timeout_seconds'] = 900

## SQS Message Consumer settings
default['xgemail']['sqs_message_consumer_inject_mta_host'] = '127.0.0.1'
default['xgemail']['sqs_message_consumer_max_number_of_messages'] = 1
default['xgemail']['sqs_message_consumer_service_name'] = 'xgemail-sqs-consumer'
default['xgemail']['sqs_message_consumer_visibility_timeout'] = 300
default['xgemail']['sqs_message_consumer_wait_time_seconds'] = 10

## Mail Pic Api settings
default['xgemail']['mail_pic_apis_response_timeout_seconds'] = 60
default['xgemail']['mail_pic_api_auth'] = "xgemail-#{node['sophos_cloud']['region']}-mail"

## Internet delivery DSN/NDR settings
XGEMAIL_SQS_MESSAGE_BOUNCER_DIR ="#{XGEMAIL_FILES_DIR}/message-bouncer"
default['xgemail']['internet_delivery_message_bouncer_processor_dir'] = XGEMAIL_SQS_MESSAGE_BOUNCER_DIR
default['xgemail']['internet_delivery_message_bouncer_common_dir'] = "#{XGEMAIL_SQS_MESSAGE_BOUNCER_DIR}/common"
default['xgemail']['internet_delivery_bounce_message_processor_user'] = 'bouncer'

## Cronjob settings
default['xgemail']['cron_job_timeout'] = '10m'
default['xgemail']['customer_delivery_transport_cron_minute_frequency'] = 5
default['xgemail']['savdid_cron_job_timeout_vdl'] = '30m'
default['xgemail']['savdid_ide_cron_minute_frequency'] = 15
default['xgemail']['submit_destination_concurrency_limit'] = 10
default['xgemail']['internet_submit_domain_cron_minute_frequency'] = 5
default['xgemail']['internet_submit_recipient_cron_minute_frequency'] = 5
default['xgemail']['xgemail_sqs_lifecycle_poller_cron_minute_frequency'] = 1

default['xgemail']['recipient_access_filename'] = 'recipient_access'
default['xgemail']['s3_encryption_algorithm'] = 'AES256'
default['xgemail']['soft_retry_senders_map_filename'] = 'soft_retry_senders_map'
default['xgemail']['tls_high_cipherlist'] = 'TLSv1.2+FIPS:kRSA+FIPS:!eNULL:!aNULL'
default['xgemail']['welcome_msg_sender'] = 'do-not-reply@cloud.sophos.com'

## Xgemail specific kernel parameters for submit and delivery
default['xgemail']['sysctl_ip_local_port_range'] = '32768 65100'
default['xgemail']['sysctl_netdev_max_backlog'] = 50000
default['xgemail']['sysctl_optmem_max'] = 40960
default['xgemail']['sysctl_swappiness'] = 10

default['xgemail']['sysctl_rmem_max'] = 33554432
default['xgemail']['sysctl_wmem_max'] = 33554432

default['xgemail']['sysctl_rmem_default'] = 33554432
default['xgemail']['sysctl_wmem_default'] = 33554432

default['xgemail']['sysctl_tcp_rmem'] = '4096 87380 33554432'
default['xgemail']['sysctl_tcp_wmem'] = '4096 87380 33554432'

default['xgemail']['sysctl_tcp_fin_timeout'] = 10
default['xgemail']['sysctl_tcp_max_syn_backlog'] = 30000
default['xgemail']['sysctl_tcp_max_tw_buckets'] = 2000000
default['xgemail']['sysctl_tcp_slow_start_after_idle'] = 0
default['xgemail']['sysctl_tcp_tw_reuse'] = 1
default['xgemail']['sysctl_tcp_window_scaling'] = 1

## Postfix configuration
SUBMIT_MESSAGE_SIZE_LIMIT_BYTES = 52428800
default['xgemail']['postfix3_version'] = '3.2.4.1-1'

POSTFIX_INBOUND_MAX_NO_OF_RCPT_PER_REQUEST = 500
POSTFIX_OUTBOUND_MAX_NO_OF_RCPT_PER_REQUEST = 500


default['xgemail']['postfix_instance_data'] = {
  # internet-submit
  'submit' => {
    :instance_name => 'is',
    :port => 25,
    :msg_size_limit => SUBMIT_MESSAGE_SIZE_LIMIT_BYTES,
    :rcpt_size_limit => POSTFIX_INBOUND_MAX_NO_OF_RCPT_PER_REQUEST
  },
  # customer-submit
  'customer-submit' => {
    :instance_name => 'cs',
    :port => 25,
    :msg_size_limit => SUBMIT_MESSAGE_SIZE_LIMIT_BYTES,
    :rcpt_size_limit => POSTFIX_OUTBOUND_MAX_NO_OF_RCPT_PER_REQUEST
  },
  # customer-delivery
  'delivery' => {
    :instance_name => 'cd',
    :port => 25,
    # Give delivery queues extra padding because extra content may be created during processing
    :msg_size_limit => (SUBMIT_MESSAGE_SIZE_LIMIT_BYTES + 204800),
    :rcpt_size_limit => POSTFIX_INBOUND_MAX_NO_OF_RCPT_PER_REQUEST
  },
  # internet-delivery
  'internet-delivery' => {
    :instance_name => 'id',
    :port => 25,
    # Give delivery queues extra padding because extra content may be created during processing
    :msg_size_limit => (SUBMIT_MESSAGE_SIZE_LIMIT_BYTES + 204800),
    :rcpt_size_limit => POSTFIX_OUTBOUND_MAX_NO_OF_RCPT_PER_REQUEST
  },
  # extended-delivery
  'xdelivery' => {
    :instance_name => 'xd',
    :port => 8025,
    # Give delivery queues extra padding because extra content may be created during processing
    :msg_size_limit => (SUBMIT_MESSAGE_SIZE_LIMIT_BYTES + 409600),
    :rcpt_size_limit => POSTFIX_INBOUND_MAX_NO_OF_RCPT_PER_REQUEST
  },
  # internet-extended-delivery
  'internet-xdelivery' => {
    :instance_name => 'ix',
    :port => 8025,
    # Give delivery queues extra padding because extra content may be created during processing
    :msg_size_limit => (SUBMIT_MESSAGE_SIZE_LIMIT_BYTES + 409600),
    :rcpt_size_limit => POSTFIX_OUTBOUND_MAX_NO_OF_RCPT_PER_REQUEST
  },
#  # customer-encryption-delivery
#  'encryption-delivery' => {
#    :instance_name => 'ed',
#    :port => 8587,
#    # Give delivery queues extra padding because extra content may be created during processing
#    :msg_size_limit => (SUBMIT_MESSAGE_SIZE_LIMIT_BYTES + 204800)
#  },
    # customer-encryption
     'customer-encryption' => {
        :instance_name => 'ce',
       :port => 25,
       # Give delivery queues extra padding because extra content may be created during processing
       :msg_size_limit => (SUBMIT_MESSAGE_SIZE_LIMIT_BYTES + 204800)
     },
  # customer-encryption-submit
   'encryption-submit' => {
     :instance_name => 'es',
     :port => 587,
     # Give delivery queues extra padding because extra content may be created during processing
     :msg_size_limit => (SUBMIT_MESSAGE_SIZE_LIMIT_BYTES + 204800)
   }
}

## The Postfix instance name for the customer-encryption node
default['xgemail']['customer_encryption_postfix_instance_name'] = 'ed'

default['xgemail']['common_instance_config_params'] = [
  # Disable special handling of owner- prefix
  # Without it the system goes into tailspin when hosts in transport file
  # cannot be resolved, producing mail to 'owner-owner-owner-owner-owner...'
  'owner_request_special = no',

  'enable_long_queue_ids=yes'
]

default['xgemail']['no_local_delivery_config_params'] = [
  # No local delivery on these instances
  #
  'mydestination =',
  'alias_maps =',
  'alias_database =',
  'local_recipient_maps =',
  'local_transport = error:5.1.1 Mailbox unavailable',

  # No header rewriting
  'local_header_rewrite_clients ='
]
