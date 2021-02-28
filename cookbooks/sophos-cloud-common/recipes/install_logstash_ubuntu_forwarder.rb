#
# Cookbook Name:: sophos-cloud-common
# Recipe:: install_logstash_ubuntu_forwarder
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

cookbook_file "deb-logstash-forwarder.repo" do
  path "/etc/apt/sources.list.d/logstash.list"
  source "deb-logstash-forwarder.repo"
  mode "0444"
  owner "root"
  group "root"
end

bash "Setup GPG-KEY" do
  user "root"
  group "root"
  code "wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -"
end

bash "Update apt-get" do
  user "root"
  group "root"
  code "apt-get update"
end

bash "Install Logstash" do
  user "root"
  group "root"
  code "apt-get install logstash logstash-forwarder"
end
