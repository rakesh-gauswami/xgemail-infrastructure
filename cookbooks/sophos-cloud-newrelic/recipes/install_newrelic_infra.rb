#
# Cookbook:: sophos-cloud-newrelic
# Recipe:: install_newrelic_infra
#
# Copyright:: 2022, Sophos 2022, All Rights Reserved.

LOGS_OWNER = 'root'

NEWRELIC_INFRA_LOG_LOCATION = newrelic_infra_log_location()
NEWRELIC_INFRA_BIN_LOCATION = newrelic_infra_bin_location()
NEWRELIC_INFRA_SERVICE = node['newrelic']['infra']['service']
NEWRELIC_INFRA_VERSION = node['newrelic']['infra']['version']
NEWRELIC_INFRA_ARCH = node['newrelic']['infra']['arch']
NEWRELIC_INFRA_AGENT_RPM_NAME = newrelic_infra_agent_rpm_name()
NEWRELIC_INFRA_INSTALL_STATUS = "#{Chef::Config['file_cache_path']}/newrelic-infra-install.status"

SYSTEMD_UNIT_RESOURCE = "systemd_unit[#{NEWRELIC_INFRA_SERVICE}]"

NEWRELIC_GROUP = node['newrelic']['group']

yum_repository NEWRELIC_INFRA_SERVICE do
  description       'New Relic Infrastructure'
  enabled           true
  baseurl           'https://download.newrelic.com/infrastructure_agent/linux/yum/amazonlinux/2/x86_64/'
  gpgkey            'https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg'
  gpgcheck          true
  repo_gpgcheck     true
  make_cache        true
  mode '0644'

  action            :create
end

directory NEWRELIC_INFRA_BIN_LOCATION do
  mode '0755'
  recursive true
end

yum_package NEWRELIC_INFRA_SERVICE do
  version   NEWRELIC_INFRA_VERSION
  arch      NEWRELIC_INFRA_ARCH
  notifies :stop, SYSTEMD_UNIT_RESOURCE, :immediately
  notifies :disable, SYSTEMD_UNIT_RESOURCE, :immediately
  notifies :create, "file[#{NEWRELIC_INFRA_INSTALL_STATUS}]", :immediately

  action   :install

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
