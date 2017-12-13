#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: start_nginx -- this runs during AMI deployment
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Start nginx
bash "nginx" do
  user "nginx"
  cwd "/tmp"
  code <<-EOH
    service nginx start
  EOH
  only_if { node['sophos_cloud']['cluster'] == 'hub' }
end