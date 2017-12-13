#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_remote_user_keys
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

ENV    = node['sophos_cloud']['environment']
REGION = node['sophos_cloud']['region']
VPC    = node['sophos_cloud']['vpc_name']
USER   = node['sophos_cloud_common']['remote_user']
GROUP  = 'remote_users'

BUCKET      = "cloud-#{ENV}-connections"
REMOTE_PATH = "#{BUCKET}/#{REGION}/#{VPC}/ssh/pub"
HOME_DIR    = "/home/#{USER}"
LOCAL_PATH  = "#{HOME_DIR}/.ssh"
KEY         = "#{USER}.pub"

log "Create Remote User Group: #{GROUP} and Remote User: #{USER}" do
  level :info
end

group GROUP do
  action :create
end

user USER do
  group GROUP
  shell "/bin/bash"
  home HOME_DIR
  action :create
end

cookbook_file "remote_users.etc.sudoers.d" do
  path "/etc/sudoers.d/remote_users"
  source "remote_users.etc.sudoers.d"
  mode "0440"
  owner "root"
  group "root"
end

log "Download from S3://#{REMOTE_PATH}/#{KEY} to #{LOCAL_PATH}/#{KEY}" do
  level :info
end

directory LOCAL_PATH do
  mode "0700"
  owner USER
  group GROUP
  recursive true
end

bash "download_remote_user_ssh_public_key" do
  user "root"
  cwd LOCAL_PATH
  code <<-EOH 
    aws --region us-west-2 s3 cp s3://#{REMOTE_PATH}/#{KEY} #{LOCAL_PATH} || /bin/touch #{LOCAL_PATH}/#{KEY}
    /bin/chmod 0600 #{LOCAL_PATH}/#{KEY}
    /bin/chown #{USER} #{LOCAL_PATH}/#{KEY}
  EOH
end

log "Adding #{KEY} to #{USER} authorized_keys" do
  level :info
end

bash "add_remote_user_ssh_public_key_to_authorized_keys" do
  user "root"
  cwd LOCAL_PATH
  code <<-EOH
    /bin/touch #{LOCAL_PATH}/authorized_keys
    /bin/cat #{LOCAL_PATH}/#{KEY} >> #{LOCAL_PATH}/authorized_keys
    /bin/chmod 0600 #{LOCAL_PATH}/authorized_keys
    /bin/chown #{USER} #{LOCAL_PATH}/authorized_keys
    rm -f #{LOCAL_PATH}/#{KEY}
  EOH
end
