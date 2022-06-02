#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure_swaks
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

ACCOUNT_NAME = node['sophos_cloud']['account_name']
NODE_TYPE    = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

SOPHOS_SWAKS_DIR = '/opt/swaks'

directory SOPHOS_SWAKS_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

bash 'download_swaks' do
  user 'root'
  cwd '/opt/swaks'
  code <<-EOH
    echo "$(curl -O https://jetmore.org/john/code/swaks/files/swaks-20201014.0/swaks)"
    /bin/chmod +x /opt/swaks/swaks
  EOH
end

template 'send_warmup_emails.sh' do
  path "#{SOPHOS_SWAKS_DIR}/send_warmup_emails.sh"
  source 'xgemail.swaks.send.warmup.emails.sh.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template 'subjectline.txt' do
  path "#{SOPHOS_SWAKS_DIR}/subjectline.txt"
  source 'xgemail.swaks.subjectline.txt.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template 'update_subject.sh' do
  path "#{SOPHOS_SWAKS_DIR}/update_subject.sh"
  source 'xgemail.swaks.update.subject.sh.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template 'send100emails.sh' do
  path "#{SOPHOS_SWAKS_DIR}/send100emails.sh"
  source 'xgemail.swaks.send100emails.sh.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :sophos_swaks_dir => SOPHOS_SWAKS_DIR
  )
end

template 'send50emails.sh' do
  path "#{SOPHOS_SWAKS_DIR}/send50emails.sh"
  source 'xgemail.swaks.send50emails.sh.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :sophos_swaks_dir => SOPHOS_SWAKS_DIR
  )
end

template 'send20emails.sh' do
  path "#{SOPHOS_SWAKS_DIR}/send20emails.sh"
  source 'xgemail.swaks.send20emails.sh.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :sophos_swaks_dir => SOPHOS_SWAKS_DIR
  )
end
