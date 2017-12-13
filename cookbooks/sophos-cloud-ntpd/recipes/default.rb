# Cookbook Name:: sophos-cloud-ntpd
# Recipe:: configure -- this runs during AMI deployment
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure ntpd

package "ntp" do
  action :install
end

cookbook_file "/tmp/vpc_detail.sh" do
  source "vpc_detail.sh"
  mode "0755"
  owner "root"
  group "root"
  action :create_if_missing
end

execute "vpc_detail file" do
  command "sh /tmp/vpc_detail.sh"
end

ruby_block "Replace vpc cidr in attribute variable" do
  block do
    f = File.open("/tmp/result.log","r")
    f.each_line {|line|
      node.default[:ntp][:vpc_cidr_string] = line.chomp
    }
  end
end

template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  notifies :restart, "service[#{node[:ntp][:service]}]"
end

service node[:ntp][:service] do
  service_name node[:ntp][:service]
  action [:enable,:restart]
end
