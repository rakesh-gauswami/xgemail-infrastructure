#
# Cookbook Name:: sophos-central-diag
# Recipe:: install
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#

directory "/opt/sophos/etc/diag.d" do
  owner "root"
  group "root"
  mode  "0755"
  recursive true
end

cookbook_file "diag" do
  path "/opt/sophos/bin/diag"
  source "diag.sh"
  mode "0755"
  owner "root"
  group "root"
end

link "/usr/bin/diag" do
  to "/opt/sophos/bin/diag"
end
