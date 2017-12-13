#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_savi
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Install Sophos Anti-Virus.

bash "install_savi_client" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    set -e

    mkdir -p /tmp/savi
    aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['savi']} /tmp/savi
    tar -xzvf /tmp/savi/savi-install.tar.gz -C /tmp/savi/

    pushd /tmp/savi/savi-install
    bash install.sh
    popd

    rm -rf /tmp/savi /tmp/savi-install.tar.gz
  EOH
end
