#
# Cookbook:: sophos-cloud-newrelic
# Recipe:: install_newrelic_infra
#
# Copyright:: 2022, Sophos 2022, All Rights Reserved.

LOGS_OWNER = 'root'

NEWRELIC_INFRA_LOG_LOCATION = newrelic_infra_log_location()
NEWRELIC_INFRA_BIN_LOCATION = newrelic_infra_bin_location()
NEWRELIC_INFRA_VERSION = node['newrelic']['infra']['version']
NEWRELIC_INFRA_SERVICE = "newrelic-infra"
NEWRELIC_INFRA_INSTALL_STATUS = "#{Chef::Config['file_cache_path']}/newrelic-infra-install.status"
NEWRELIC_INFRA_AGENT_RPM_NAME = newrelic_infra_agent_rpm_name()

SYSTEMD_UNIT_RESOURCE = "systemd_unit[#{NEWRELIC_INFRA_SERVICE}]"

NEWRELIC_GROUP = node['newrelic']['group']

cookbook_file "/etc/yum.repos.d/#{NEWRELIC_INFRA_SERVICE}.repo" do
  path "/etc/yum.repos.d/#{NEWRELIC_INFRA_SERVICE}.repo"
  source "#{NEWRELIC_INFRA_SERVICE}.repo"
  mode '0644'
  owner 'root'
  group 'root'
end

execute 'yum makecache' do
  user 'root'
  command <<-EOH
      yum -q makecache -y --disablerepo='*' --enablerepo='#{NEWRELIC_INFRA_SERVICE}'
  EOH
end

directory NEWRELIC_INFRA_BIN_LOCATION do
  mode '0755'
  recursive true
end

yum_package NEWRELIC_INFRA_SERVICE do
  action :install
  version NEWRELIC_INFRA_VERSION
  notifies :stop, SYSTEMD_UNIT_RESOURCE, :immediately
  notifies :disable, SYSTEMD_UNIT_RESOURCE, :immediately
  notifies :create, "file[#{NEWRELIC_INFRA_INSTALL_STATUS}]", :immediately

  not_if { ::File.exist?("#{NEWRELIC_INFRA_INSTALL_STATUS}") }
end

# Note that the NewRelic yum installation by default sets up the newrelic-infra agent with systemd
systemd_unit NEWRELIC_INFRA_SERVICE do
  action :nothing
end

file NEWRELIC_INFRA_INSTALL_STATUS do
  content "NewRelic-Infra installed\n"
  action :nothing
end

# Note that the install script for the newrelic-infra agent will auto-create a log directory at '/var/log/newrelic-infra'
# For now, we'll use the same directory for logging and change the permissions on that directory.
# If you decide you want to use a different directory for logging, given that the newrelic-infra agent creates the above
# directory by default, you will have to add a delete action in chef here for it.
directory NEWRELIC_INFRA_LOG_LOCATION do
  mode '0755'
  recursive true
end
