#
# Cookbook Name:: sophos-cloud-common
# Recipe:: common_docker
#
# Copyright 2017 Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group.
# All other product and company names mentioned are trademarks or registered trademarks of their
# respective owners.
#

package 'docker'

directory '/etc/docker'

cookbook_file '/etc/docker/daemon.json' do
  source 'daemon.json'
end

service 'docker' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [ :enable, :start ]
end
