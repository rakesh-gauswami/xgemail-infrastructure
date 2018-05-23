#
# Cookbook Name:: ophos-cloud-xgemail
# Recipe:: install_fluentd.rb
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

# TD-Agent
TDAGENT_PACKAGE_VERSION = "#{node['xgemail']['tdagent_version']}"
TDAGENT_PACKAGE_NAME = "td-agent-#{TDAGENT_PACKAGE_VERSION}"

yum_package 'redhat-lsb-core' do
  action :install
end

directory '/opt/sophos/packages' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

execute 'download_packages' do
  user 'root'
  cwd '/opt/sophos/packages'
  command <<-EOH
      aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['thirdparty']}/xgemail/#{TDAGENT_PACKAGE_NAME}.tar.gz .
  EOH
end

# Extract td-agent files
execute 'extract td-agent files' do
  user 'root'
  cwd '/opt/sophos/packages'
  command <<-EOH
    tar xf #{TDAGENT_PACKAGE_NAME}.tar.gz
  EOH
end

rpm_package 'install td-agent' do
  action :install
  package_name "#{TDAGENT_PACKAGE_NAME}.el6.x86_64.rpm"
  source "/opt/sophos/packages/#{TDAGENT_PACKAGE_NAME}.el6.x86_64.rpm"
end

directory '/etc/td-agent.d' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

cookbook_file '/etc/sysconfig/td-agent' do
  path '/etc/sysconfig/td-agent'
  source 'td-agent'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

cookbook_file '/etc/td-agent/td-agent.conf' do
  path '/etc/td-agent/td-agent.conf'
  source 'td-agent.conf'
  mode '0644'
  owner 'root'
  group 'root'
end

service 'td-agent' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [ :disable, :stop ]
end

cookbook_file '/etc/security/limits.conf' do
  path '/etc/security/limits.conf'
  source 'limits.conf'
  mode '0644'
  owner 'root'
  group 'root'
end

# Modify /etc/rsyslog.conf
ruby_block 'edit rsyslog.conf' do
    block do
        ['$SystemLogRateLimitInterval 2',
         '$SystemLogRateLimitBurst 500'
        ].each do |line|
            file = Chef::Util::FileEdit.new('/etc/rsyslog.conf')
            file.insert_line_if_no_match(/#{line}/, line)
            file.write_file
        end
    end
end