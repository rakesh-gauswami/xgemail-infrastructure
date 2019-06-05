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

if ACCOUNT != 'sandbox'

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

else

  execute 'download_packages' do
    user 'root'
    cwd '/opt/sophos/packages'
    command <<-EOH
      wget http://packages.treasuredata.com.s3.amazonaws.com/3/redhat/7/x86_64/#{TDAGENT_PACKAGE_NAME}.el7.x86_64.rpm
    EOH
  end

  rpm_package 'install td-agent' do
    action :install
    package_name "#{TDAGENT_PACKAGE_NAME}.el7.x86_64.rpm"
    source "/opt/sophos/packages/#{TDAGENT_PACKAGE_NAME}.el7.x86_64.rpm"
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

cookbook_file '/etc/sysconfig/td-agent' do
  path '/etc/sysconfig/td-agent'
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

# Temporary to update td-agent to latest version until 3rdparty package script can be updated in cloud-infrastructure
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

if ACCOUNT != 'sandbox'

  yum_package 'td-agent' do
    action :upgrade
    flush_cache [ :before ]
  end

end


execute 'uninstall td-agent fluent-plugin-s3' do
  user 'root'
  command <<-EOH
      td-agent-gem uninstall fluent-plugin-s3
  EOH
end

execute 'install td-agent fluent-plugin-s3' do
  user 'root'
  command <<-EOH
      td-agent-gem install fluent-plugin-s3 -v 1.0.0
  EOH
end

execute 'install td-agent fluent-plugin-sns' do
  user 'root'
  command <<-EOH
      td-agent-gem install fluent-plugin-sns -v 3.2.0
  EOH
end

execute 'install td-agent fluent-plugin-grok-parser' do
  user 'root'
  command <<-EOH
      td-agent-gem install fluent-plugin-grok-parser
  EOH
end

if ACCOUNT != 'sandbox'
  execute 'install td-agent fluent-plugin-kinesis' do
    user 'root'
    command <<-EOH
      td-agent-gem install fluent-plugin-kinesis -v 2.1.1
    EOH
  end
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