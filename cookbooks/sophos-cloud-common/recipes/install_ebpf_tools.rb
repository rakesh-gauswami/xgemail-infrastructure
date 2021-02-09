#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_ebpf_tools
#
# Copyright 2020, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Install bcc tools, which are based on eBPF.
# References:
# - https://github.com/iovisor/bcc
# - http://www.brendangregg.com/ebpf.html

if node["platform_version"] == "2018.03"
  # Amazon Linux 1

  yum_package "kernel" do
    action :upgrade
  end
else
  # Amazon Linux 2

  execute "amazon-linux-extras enable BCC" do
    user "root"
    command "amazon-linux-extras enable BCC"
  end

  yum_package "kernel-devel-#{node["os_version"]}" do
    action :install
  end
end

yum_package "bcc" do
  action :install
end

# Add bcc tools to the default PATH for all users.

cookbook_file "bcc.sh" do
  path   "/etc/profile.d/bcc.sh"
  source "bcc.sh"
  owner  "root"
  group  "root"
  mode   "0644"
end
