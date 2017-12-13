#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_logstash_forwarder
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

template "logstash.repo" do
  path "/etc/yum.repos.d/logstash.repo"
  source "logstash.repo.erb"
  variables ({
      :version => node['sophos_cloud_common']['install_logstash_forwarder']['repository_version']
  })
  mode "0444"
  owner "root"
  group "root"
end

cookbook_file "logstash-forwarder.repo" do
  path "/etc/yum.repos.d/logstash-forwarder.repo"
  source "logstash-forwarder.repo"
  mode "0444"
  owner "root"
  group "root"
end

bash "import_gpg_key" do
  user "root"
  code "rpm --import http://packages.elasticsearch.org/GPG-KEY-elasticsearch"
end

yum_package "logstash-forwarder" do
  action :install
end

yum_package "logstash" do
  action :install
end
