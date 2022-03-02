#
# Cookbook:: sophos_tomcat
# Recipe:: install_newrelic_infra
#
# Copyright:: 2020, Sophos 2020, All Rights Reserved.

LOGS_OWNER = 'root'

NEWRELIC_INFRA_LOG_LOCATION = newrelic_infra_log_location()
NEWRELIC_INFRA_BIN_LOCATION = newrelic_infra_bin_location()
NEWRELIC_INFRA_JMX_CONF_LOCATION = newrelic_infra_prometheus_jmx_conf_file_location()
NEWRELIC_INFRA_VERSION = node['newrelic']['infra']['version']
NEWRELIC_INFRA_JMX_VERSION = node['newrelic']['infra']['jmx']['version']
NEWRELIC_INFRA_SERVICE = "newrelic-infra"
NEWRELIC_INFRA_INSTALL_STATUS = "#{Chef::Config['file_cache_path']}/newrelic-infra-install.status"
NEWRELIC_INFRA_AGENT_RPM_NAME = newrelic_infra_agent_rpm_name()
NEWRELIC_NRI_JMX_RPM_NAME = newrelic_nri_jmx_rpm_name()
NEWRELIC_NRJMX_RPM_NAME = newrelic_nrjmx_rpm_name()
PROMETHEUS_JMX_EXPORTER_JAR_PATH = newrelic_prometheus_jar_path()
PROMETHEUS_JMX_EXPORTER_JAR_NAME = newrelic_prometheus_jar_name()
PROMETHEUS_JMX_EXPORTER_DIR = node['newrelic']['infra']['prometheus']['destination']

SYSTEMD_UNIT_RESOURCE = "systemd_unit[#{NEWRELIC_INFRA_SERVICE}]"

TOMCAT_GROUP = node['tomcat']['group']

directory NEWRELIC_INFRA_BIN_LOCATION do
  mode '0755'
  recursive true
end

yum_package NEWRELIC_INFRA_AGENT_RPM_NAME do
  action :install
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

yum_package NEWRELIC_NRJMX_RPM_NAME do
  action :install
  options "--nogpgcheck"
end

yum_package NEWRELIC_NRI_JMX_RPM_NAME do
  action :install
end

# Note that the install script for the newrelic-infra agent will auto-create a log directory at '/var/log/newrelic-infra'
# For now, we'll use the same directory for logging and change the permissions on that directory.
# If you decide you want to use a different directory for logging, given that the newrelic-infra agent creates the above
# directory by default, you will have to add a delete action in chef here for it.
directory NEWRELIC_INFRA_LOG_LOCATION do
  mode '0755'
  recursive true
end

directory PROMETHEUS_JMX_EXPORTER_DIR do
  mode '0755'
  recursive true
end

directory NEWRELIC_INFRA_JMX_CONF_LOCATION do
  mode '0755'
  recursive true
end

artifactory_artifact PROMETHEUS_JMX_EXPORTER_JAR_PATH do
  artifactory_url 'https://artifactory.sophos-tools.com/artifactory'
  repository 'performance-local-releases'
  repository_path "jmx/#{PROMETHEUS_JMX_EXPORTER_JAR_NAME}"
end