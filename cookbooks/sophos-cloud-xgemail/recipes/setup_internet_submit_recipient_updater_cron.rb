#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_internet_submit_recipient_updater_cron
#
# Copyright 2016, Sophos
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
LOCAL_CERT_PATH       = node['sophos_cloud']['local_cert_path']
REGION                = node['sophos_cloud']['region']
CONNECTIONS_BUCKET    = node['sophos_cloud']['connections']

CRON_JOB_TIMEOUT      = node['xgemail']['cron_job_timeout']
CRON_MINUTE_FREQUENCY = node['xgemail']['internet_submit_recipient_cron_minute_frequency']
STATION_VPC_NAME      = node['xgemail']['station_vpc_name']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']
RECIPIENT_ACCESS_FILENAME = node['xgemail']['recipient_access_filename']
RELAY_DOMAINS_FILENAME = 'relay_domains'
MAIL_PIC_API_RESPONSE_TIMEOUT = node['xgemail']['mail_pic_apis_response_timeout_seconds']
MAIL_PIC_API_AUTH = node['xgemail']['mail_pic_api_auth']

if ACCOUNT == 'sandbox'
  RECIPIENT_ACCESS_FILE = "/etc/#{instance_name(INSTANCE_NAME)}/#{RECIPIENT_ACCESS_FILENAME}"
  file RECIPIENT_ACCESS_FILE do
    content "#{node['sandbox']['mail_recipient_access']}\n"
    mode '0644'
    owner 'root'
  end

  execute 'build_postmap_for_recipient_access' do
    user 'root'
    command <<-EOH
          postmap #{RECIPIENT_ACCESS_FILE}
    EOH
  end

  [
    'smtpd_recipient_restrictions = ' +
      "check_recipient_access hash:$config_directory/#{RECIPIENT_ACCESS_FILENAME}, " +
      'reject'
  ].each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end

  # Return, don't create CRON job
  return

end

PACKAGE_DIR = "#{XGEMAIL_FILES_DIR}/internet-submit-recipient-cron"
CRON_SCRIPT = 'internet.submit.recipient.updater.py'
CRON_SCRIPT_PATH = "#{PACKAGE_DIR}/#{CRON_SCRIPT}"

XGEMAIL_PIC_CA_PATH = "#{LOCAL_CERT_PATH}/hmr-infrastructure-ca.crt"
XGEMAIL_PIC_FQDN = "mail-#{STATION_VPC_NAME.downcase}-#{REGION}.#{ACCOUNT}.hydra.sophos.com"

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
  ignore_failure true
  user 'root'
  action :nothing
end

template CRON_SCRIPT_PATH do
  source "#{CRON_SCRIPT}.erb"
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :xgemail_pic_ca_path => XGEMAIL_PIC_CA_PATH,
    :xgemail_pic_fqdn => XGEMAIL_PIC_FQDN,
    :postfix_instance_name => instance_name( INSTANCE_NAME ),
    :recipient_access_filename => RECIPIENT_ACCESS_FILENAME,
    :relay_domains_filename => RELAY_DOMAINS_FILENAME,
    :mail_pic_api_response_timeout => MAIL_PIC_API_RESPONSE_TIMEOUT,
    :mail_pic_api_auth => MAIL_PIC_API_AUTH,
    :connections_bucket => CONNECTIONS_BUCKET
  )
  notifies :run, "execute[#{CRON_SCRIPT_PATH}]", :immediately
end

cron "#{INSTANCE_NAME}-recipient-cron" do
  minute "3-59/#{CRON_MINUTE_FREQUENCY}"
  user 'root'
  command "source /etc/profile && timeout #{CRON_JOB_TIMEOUT} flock --nb /var/lock/#{CRON_SCRIPT}.lock -c '#{CRON_SCRIPT_PATH}' >/dev/null 2>&1"
end
