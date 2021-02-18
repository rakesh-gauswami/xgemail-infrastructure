#
# Cookbook Name:: sophos-cloud-fluentd
# Recipe:: install
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

ACCOUNT = node['sophos_cloud']['account']

# TD-Agent
CONF_DIR              = node['fluentd']['conf_dir']
MAIN_DIR              = node['fluentd']['main_dir']
PATTERNS_DIR          = node['fluentd']['patterns_dir']
PLUGIN_DIR            = node['fluentd']['plugin_dir']
TDAGENT_PACKAGE_VERSION = "#{node['fluentd']['tdagent_version']}"
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

cookbook_file '/etc/yum.conf' do
  path '/etc/yum.conf'
  source 'yum.conf'
  mode '0644'
  owner 'root'
  group 'root'
end

execute 'import td-agent repo key' do
  user 'root'
  command <<-EOH
      rpm --import https://packages.treasuredata.com/GPG-KEY-td-agent
  EOH
end

cookbook_file '/etc/yum.repos.d/td.repo' do
  path '/etc/yum.repos.d/td.repo'
  source 'td.repo'
  mode '0644'
  owner 'root'
  group 'root'
end

execute 'clean yum cache' do
  user 'root'
  command <<-EOH
      yum clean all
  EOH
end

if ACCOUNT != 'sandbox'

  yum_package 'td-agent' do
    action :install
    version "#{TDAGENT_PACKAGE_VERSION}"
    flush_cache [ :before ]
  end

end

directory CONF_DIR do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory PATTERNS_DIR do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory PLUGIN_DIR do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

cookbook_file '/etc/systemd/system/td-agent.service' do
  path '/etc/systemd/system/td-agent.service'
  source 'td-agent'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
end

template 'td-agent.conf' do
  path "#{MAIN_DIR}/td-agent.conf"
  source 'td-agent.conf'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :conf_dir => CONF_DIR
  )
end

execute 'install td-agent fluent-plugin-sns' do
  user 'root'
  command <<-EOH
      td-agent-gem install fluent-plugin-sns -v 3.2.0
  EOH
end

execute 'install td-agent fluent-plugin-sqs' do
  user 'root'
  command <<-EOH
      td-agent-gem install fluent-plugin-sqs -v 3.0.0
  EOH
end

execute 'install td-agent fluent-plugin-grok-parser' do
  user 'root'
  command <<-EOH
      td-agent-gem install fluent-plugin-grok-parser -v 2.6.0
  EOH
end

execute 'install td-agent fluent-plugin-out-http' do
  user 'root'
  command <<-EOH
      td-agent-gem install fluent-plugin-out-http -v 1.3.3
  EOH
end

if ACCOUNT != 'sandbox'
  execute 'install td-agent fluent-plugin-kinesis' do
    user 'root'
    command <<-EOH
      td-agent-gem install fluent-plugin-kinesis -v 3.1.0
    EOH
  end
end

execute 'Update aws-sdk' do
  user 'root'
  command <<-EOH
      td-agent-gem update aws-sdk --no-document
  EOH
end

# End Temporary block
#
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
