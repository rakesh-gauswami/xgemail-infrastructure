#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: setup_mf_inbound_delivery_transport_updater_cron
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe installs cron job to pull domain routing information from PIC
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

ACCOUNT               = node['sophos_cloud']['environment']
LOCAL_CERT_PATH       = node['sophos_cloud']['local_cert_path']
REGION                = node['sophos_cloud']['region']
CONNECTIONS_BUCKET    = node['sophos_cloud']['connections']

CRON_JOB_TIMEOUT      = node['xgemail']['mail_flow_cron_job_timeout']
CRON_MINUTE_FREQUENCY = node['xgemail']['mail_flow_sender_by_relay_cron_minute_frequency']
STATION_VPC_NAME      = node['xgemail']['station_vpc_name']
XGEMAIL_FILES_DIR     = node['xgemail']['xgemail_files_dir']
TRANSPORT_FILENAME    = 'transport'
MAIL_PIC_API_RESPONSE_TIMEOUT = node['xgemail']['mail_pic_apis_response_timeout_seconds']
MAIL_PIC_API_AUTH     = node['xgemail']['mail_pic_api_auth']
POLICY_BUCKET         = node['xgemail']['xgemail_policy_bucket_name']
XGEMAIL_UTILS_DIR      = node['xgemail']['xgemail_utils_files_dir']

CONFIGURATION_COMMANDS =
  [
    "transport_maps=hash:$config_directory/#{TRANSPORT_FILENAME}"
  ]

if ACCOUNT == 'sandbox'
  TRANSPORT_FILE = "/etc/#{instance_name(INSTANCE_NAME)}/#{TRANSPORT_FILENAME}"
  file TRANSPORT_FILE do
    content "#{node['sandbox']['mail_transport_entry']}\n"
    mode '0644'
    owner 'root'
  end
  CONFIGURATION_COMMANDS.each do | cur |
    execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
  end

  execute 'build_postmap_for_transport' do
    user 'root'
    command <<-EOH
          postmap #{TRANSPORT_FILE}
    EOH
  end

  # Return, don't create CRON job
  return

end

PACKAGE_DIR           = "#{XGEMAIL_FILES_DIR}/mf-inbound-delivery-transport-cron"
CRON_SCRIPT           = 'mf.inbound.delivery.transport.updater.py'
CRON_SCRIPT_PATH      = "#{PACKAGE_DIR}/#{CRON_SCRIPT}"
XGEMAIL_PIC_FQDN      = "mail-#{STATION_VPC_NAME.downcase}-#{REGION}.#{ACCOUNT}.hydra.sophos.com"

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
    :xgemail_pic_fqdn => XGEMAIL_PIC_FQDN,
    :postfix_instance_name => instance_name( INSTANCE_NAME ),
    :transport_filename => TRANSPORT_FILENAME,
    :mail_pic_api_response_timeout => MAIL_PIC_API_RESPONSE_TIMEOUT,
    :mail_pic_api_auth => MAIL_PIC_API_AUTH,
    :connections_bucket => CONNECTIONS_BUCKET,
    :policy_bucket => POLICY_BUCKET,
    :xgemail_utils_path => XGEMAIL_UTILS_DIR,
    )
  notifies :run, "execute[#{CRON_SCRIPT_PATH}]", :immediately
end

CONFIGURATION_COMMANDS.each do | cur |
  execute print_postmulti_cmd( INSTANCE_NAME, "postconf '#{cur}'" )
end

cron "#{INSTANCE_NAME}-transport-cron" do
  minute "1-59/#{CRON_MINUTE_FREQUENCY}"
  user 'root'
  command "source /etc/profile && timeout #{CRON_JOB_TIMEOUT} flock --nb /var/lock/#{CRON_SCRIPT}.lock -c '#{CRON_SCRIPT_PATH}' >/dev/null 2>&1"
end