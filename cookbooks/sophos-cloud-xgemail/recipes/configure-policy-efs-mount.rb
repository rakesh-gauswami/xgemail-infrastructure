#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-policy-efs-mount.rb
#
# Copyright 2021, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe mounts the policy EFS volume
#

NODE_TYPE = node['xgemail']['cluster_type']
POLICY_EFS_MOUNT_DIR = node['xgemail']['policy_efs_mount_dir']
POLICY_FILE_SYSTEM_ID = node['xgemail']['policy_efs_file_system_id']
AWS_REGION = node['sophos_cloud']['region']
POLICY_MOUNT_DNS_NAME = "#{POLICY_FILE_SYSTEM_ID}.efs.#{AWS_REGION}.amazonaws.com:/"

#Only mount drive for submit and customer submit nodes

if NODE_TYPE == 'internet-submit' || NODE_TYPE == 'customer-submit' || NODE_TYPE == 'mf-inbound-submit' || NODE_TYPE == 'mf-outbound-submit'

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



