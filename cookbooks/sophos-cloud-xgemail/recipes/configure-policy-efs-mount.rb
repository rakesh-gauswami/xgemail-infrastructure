#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-policy-efs-mount.rb
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe mounts the policy EFS volume
#

AWS_REGION = node['sophos_cloud']['region']
NODE_TYPE = node['xgemail']['cluster_type']
POLICY_EFS_MOUNT_DIR = node['xgemail']['policy_efs_mount_dir']
POLICY_FILE_SYSTEM_ID = node['xgemail']['policy_efs_file_system_id']
POLICY_MOUNT_DNS_NAME = "#{POLICY_FILE_SYSTEM_ID}.efs.#{AWS_REGION}.amazonaws.com:/"
POSTFIX_QUEUE_EFS_MOUNT_DIR = node['xgemail']['postfix_queue_efs_mount_dir']
POSTFIX_QUEUE_FILE_SYSTEM_ID = node['xgemail']['postfix_queue_efs_file_system_id']
POSTFIX_QUEUE_MOUNT_DNS_NAME = "#{POSTFIX_QUEUE_FILE_SYSTEM_ID}.efs.#{AWS_REGION}.amazonaws.com:/"

#Only mount policy EFS drive for submit type nodes
if NODE_TYPE == 'internet-submit' || NODE_TYPE == 'customer-submit' || NODE_TYPE == 'mf-inbound-submit' || NODE_TYPE == 'mf-outbound-submit' || NODE_TYPE == 'journal-submit'

  # Create the mount directory
  directory POLICY_EFS_MOUNT_DIR do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  mount POLICY_EFS_MOUNT_DIR do
    device POLICY_MOUNT_DNS_NAME
    fstype 'nfs4'
    options 'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2'
    action [:mount, :enable]
  end

end

#Mount postfix queue EFS drive for all postfix nodes

# Create the mount directory
directory POSTFIX_QUEUE_EFS_MOUNT_DIR do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

mount POSTFIX_QUEUE_EFS_MOUNT_DIR do
  device POSTFIX_QUEUE_MOUNT_DNS_NAME
  fstype 'nfs4'
  options 'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2'
  action [:mount, :enable]
end
