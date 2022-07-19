#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_debugging_tools
#
# Copyright 2017-2020, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Install fio, for warming disks.
# Install hdparm, for tuning disks.
# Install iotop, for monitoring I/O..
# Install jq, for parsing and filtering JSON.
# Install perf, for sampling call stacks.
# Install strace, for tracing system calls.
# Install sysstat, for iostat, mpstat, pidstat, sadf, sar.
# Install tcpdump, for tracing network traffic.
rpms_to_install = %w{fio hdparm htop iotop jq perf strace sysstat tcpdump}
rpms_to_install.each do |package|
  yum_package package do
    action :install
  end
end

# Update sysstat package's sadc configuration to collect SNMP statistics,
# so sar command can show TCP error counts.
# Eventually we'll add these counts to sareport output.
ruby_block "Update sadc configuration" do
  block do
    fe = Chef::Util::FileEdit.new("/etc/sysconfig/sysstat")
    fe.search_file_replace_line(
      'SADC_OPTIONS="-S DISK"',
      'SADC_OPTIONS="-S DISK,SNMP"')
    fe.write_file
  end
end

# Install sareport script that summarized data collected by sadc (from the sysstat package).

cookbook_file "sareport" do
  path "/opt/sophos/bin/sareport"
  source "sareport.py"
  mode "0755"
  owner "root"
  group "root"
end

link "/usr/bin/sareport" do
  to "/opt/sophos/bin/sareport"
end

# Install Brendan Gregg's flamegraph scripts.

directory "/opt/flamegraph" do
  mode "0755"
  owner "root"
  group "root"
  recursive true
end

execute 'download_flamegraph.tar.gz' do
  user 'root'
  cwd '/tmp'
  command <<-EOH
      aws --region #{node['sophos_cloud']['s3_bucket_region']} s3 cp s3:#{node['sophos_cloud']['thirdparty']}/flamegraph-1.0.tar.gz /tmp/flamegraph-1.0.tar.gz
  EOH
end

bash "unpack flamegraph files to temporary directory" do
  cwd "/tmp"
  user "root"
  code "tar xvzf /tmp/flamegraph.tar.gz -C /opt"
end

# Install script that generates CPU flamegraphs and uploads them to S3.

directory "/opt/sophos/bin" do
  mode "0755"
  owner "root"
  group "root"
  recursive true
end

cookbook_file "upload-cpu-flame-graph.sh" do
  path "/opt/sophos/bin/upload-cpu-flame-graph.sh"
  source "upload-cpu-flame-graph.sh"
  mode "0700"
  owner "root"
  group "root"
end

link "/usr/bin/upload-cpu-flame-graph.sh" do
  to "/opt/sophos/bin/upload-cpu-flame-graph.sh"
end

# Install script that filters input, replacing instance hostnames and addresses with their Name tags.

cookbook_file "ec2filter" do
  path "/opt/sophos/bin/ec2filter"
  source "ec2filter.py"
  mode "0755"
  owner "root"
  group "root"
end

link "/usr/bin/ec2filter" do
  to "/opt/sophos/bin/ec2filter"
end

# Make ec2-metadata available to SSM RunShellScript by putting it in the PATH.

link "/usr/bin/ec2-metadata" do
  to "/opt/aws/bin/ec2-metadata"
end
