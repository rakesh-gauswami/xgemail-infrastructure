#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_internet_submit_recipient_updater_cron
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs cron job to pull recipient information from PIC
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

ACCOUNT               = node['sophos_cloud']['context']
ACCOUNT_NAME          = node['sophos_cloud']['account_name']
LOCAL_CERT_PATH       = node['sophos_cloud']['local_cert_path']
REGION                = node['sophos_cloud']['region']
CONNECTIONS_BUCKET    = node['sophos_cloud']['connections']

CRON_JOB_TIMEOUT      = node['xgemail']['cron_job_timeout']
CRON_MINUTE_FREQUENCY = node['xgemail']['internet_submit_recipient_cron_minute_frequency']
STATION_VPC_NAME      = node['xgemail']['station_vpc_name']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']
RECIPIENT_ACCESS_FILENAME = node['xgemail']['recipient_access_filename']
RECIPIENT_ACCESS_EXTRA_FILENAME = node['xgemail']['recipient_access_extra_filename']
RELAY_DOMAINS_FILENAME = node['xgemail']['relay_domains_filename']
MAIL_PIC_API_RESPONSE_TIMEOUT = node['xgemail']['mail_pic_apis_response_timeout_seconds']
MAIL_PIC_API_AUTH = node['xgemail']['mail_pic_api_auth']
PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/internet-submit-recipient-cron"
CRON_SCRIPT = 'internet.submit.recipient.updater.py'
CRON_SCRIPT_PATH = "#{PACKAGE_DIR}/#{CRON_SCRIPT}"

if ACCOUNT == 'sandbox'
  XGEMAIL_PIC_FQDN = 'mail-service:8080'
else
  if ACCOUNT_NAME == 'legacy'
    XGEMAIL_PIC_FQDN = "mail-#{STATION_VPC_NAME.downcase}-#{REGION}.#{ACCOUNT}.hydra.sophos.com"
  else
    XGEMAIL_PIC_FQDN = "mail.#{node['sophos_cloud']['parent_account_name']}.ctr.sophos.com"
  end
end

directory XGEMAIL_FILES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
end

# Setup cron script execution
execute CRON_SCRIPT_PATH do
  ignore_failure false
  user 'root'
  action :nothing
end

template CRON_SCRIPT_PATH do
  source "#{CRON_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :xgemail_pic_fqdn => XGEMAIL_PIC_FQDN,
    :postfix_instance_name => instance_name( INSTANCE_NAME ),
    :recipient_access_filename => RECIPIENT_ACCESS_FILENAME,
    :recipient_access_extra_filename => RECIPIENT_ACCESS_EXTRA_FILENAME,
    :relay_domains_filename => RELAY_DOMAINS_FILENAME,
    :mail_pic_api_response_timeout => MAIL_PIC_API_RESPONSE_TIMEOUT,
    :mail_pic_api_auth => MAIL_PIC_API_AUTH,
    :connections_bucket => CONNECTIONS_BUCKET,
    :account => ACCOUNT
  )
end
