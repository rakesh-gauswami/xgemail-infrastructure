#
# Cookbook Name:: sophos-cloud-mount
# Recipe:: install
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

ACCOUNT     = node["sophos_cloud"]["environment"]
REGION      = node["sophos_cloud"]["region"]
VPC_NAME    = node["sophos_cloud"]["vpc_name"]
CONNECTIONS = node["sophos_cloud"]["connections"]

VOLUME_MOUNT_POINT = node["volumes"]["volume_mount_point"]

VOLUME_SNAPSHOT_HOUR     = node["volumes"]["volume_snapshot_hour"]
VOLUME_SNAPSHOT_WEEKDAY  = node["volumes"]["volume_snapshot_weekday"]

if node[:platform] == 'ubuntu'
  # Install the boto3 python AWS SDK.
  # http://boto3.readthedocs.org/en/latest/
  bash "install boto3" do
    user "root"
    code "pip install boto3"
  end
end

# Install scripts to manage EBS volumes.
directory "/root/bin" do
  mode "0750"
  owner "root"
  group "root"
end

cookbook_file "manage-ebs-volumes.py" do
  path "/root/bin/manage-ebs-volumes.py"
  mode "0750"
  owner "root"
  group "root"
end

# Attach EBS volumes and mount them before writing anything.

# Create required directories.
directory VOLUME_MOUNT_POINT do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

bash "install volume set" do
  user "root"
  not_if "grep -qs #{VOLUME_MOUNT_POINT} /proc/mounts"
  code "/root/bin/manage-ebs-volumes.py install --verbose"
  retries 30 # [CPLAT-10795] Retry until device exists.
  retry_delay 10  
end

# Enable regular snapshotting

cron "snapshot_volumes_cron" do
  minute "0"
  hour VOLUME_SNAPSHOT_HOUR
  weekday VOLUME_SNAPSHOT_WEEKDAY
  user "root"
  command "/root/bin/manage-ebs-volumes.py backup"
end

if node[:platform] == 'ubuntu'
  # boto3 downgrades botocore to 1.1.12,
  # Re-install awscli: replace botocore 1.1.12 by the one needed by awscli
  bash "update awscli" do
    user "root"
    code "pip install awscli"
  end
end
