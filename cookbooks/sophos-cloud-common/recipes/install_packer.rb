#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_packer
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Install Sophos Anti-Virus.

bash "install_packer" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    set -e
    PACKER_VERSION=0.10.1
    PACKER_BUCKET=cloud-applications-3rdparty
    PACKER_KEY=packer/packer-${PACKER_VERSION}.tar.gz
    /usr/bin/aws --region us-west-2 s3 cp s3://${PACKER_BUCKET}/${PACKER_KEY} packer.tar.gz
    /bin/tar xzvf packer.tar.gz
    /bin/mv packer /usr/bin/packer
    /bin/chmod 755 /usr/bin/packer
    /bin/rm -rf packer.tar.gz
  EOH
end
