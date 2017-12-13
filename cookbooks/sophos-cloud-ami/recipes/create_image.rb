#
# Cookbook Name:: sophos-cloud-ami
# Recipe:: create_image
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

template "create-image.sh" do
  path "/tmp/create-image.sh"
  source "create-image.sh.erb"
  mode "0644"
  owner "root"
  group "root"
end

bash "run create_image.sh" do
  user "root"
  code "bash /tmp/create-image.sh"
end
