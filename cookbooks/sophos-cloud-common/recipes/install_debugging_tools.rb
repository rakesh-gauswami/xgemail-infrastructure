#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_debugging_tools
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Install fio, for warming disks.
# Install hdparm, for tuning disks.
# Install jq, for parsing and filtering JSON.
# Install strace, for tracing system calls.
# Install sysstat, for iostat, mpstat, pidstat, sadf, sar.
rpms_to_install = %w{fio hdparm jq strace sysstat}
rpms_to_install.each do |package|
  yum_package package do
    action :install
  end
end
