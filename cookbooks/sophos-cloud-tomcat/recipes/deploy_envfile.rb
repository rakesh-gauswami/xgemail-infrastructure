#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: deploy_envfile -- this runs during AMI deployment
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#

tomcat_path = node['tomcat']['dir']


##
# Download tcell before copying setenv.sh so that it can be there
##
s3_file "/tmp/#{node['sophos_cloud']['tcell']}" do
  bucket node['sophos_cloud']['thirdparty']
  remote_path "/tcell/#{node['sophos_cloud']['tcell']}"
  mode '0600'
  only_if { ['inf' ].include? node['sophos_cloud']['context'] }
end

tar_extract "/tmp/#{node['sophos_cloud']['tcell']}" do
  action :extract_local
  target_dir "#{node['tomcat']['dir']}"
  only_if { ['inf' ].include? node['sophos_cloud']['context'] }
end

s3_file "#{node['tomcat']['dir']}/tcell/tcell_agent.config" do
  bucket node['sophos_cloud']['thirdparty']
  remote_path "/tcell/tcell_agent.config"
  only_if { ['inf' ].include? node['sophos_cloud']['context'] }
end

directory "#{node['tomcat']['dir']}/tcell" do
  owner 'tomcat'
  group 'tomcat'
  mode '0744'
  recursive true
end

template "setenv.sh" do
  path "#{tomcat_path}/bin/setenv.sh"
  source "setenv.sh.erb"
  mode "0444"
  owner "root"
  group "tomcat"
end