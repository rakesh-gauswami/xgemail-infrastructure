#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: start_tomcat -- this runs during AMI deployment
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
is_java_app = node['sophos_cloud']['is_java_app'] == "yes"

execute "tomcat start" do
  command node['tomcat']['start_command']
  ignore_failure false
  only_if { is_java_app }
end