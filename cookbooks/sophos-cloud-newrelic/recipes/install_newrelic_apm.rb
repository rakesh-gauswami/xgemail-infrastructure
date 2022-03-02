#
# Cookbook:: sophos_tomcat
# Recipe:: install_newrelic_apm
#
# Copyright:: 2020, Sophos 2020, All Rights Reserved.

NEWRELIC_APM_ARTIFACT_ID = node['newrelic']['apm']['artifact_id']
NEWRELIC_APM_DESTINATION = newrelic_apm_destination()
NEWRELIC_APM_VERSION = node['newrelic']['apm']['version']

NEWRELIC_APM_JAR_PATH = newrelic_apm_jar_path()
NEWRELIC_APM_JAR_NAME = newrelic_apm_jar_name()

NEWRELIC_APM_INSTALL_BASE = node['newrelic']['install_base']
NEWRELIC_APM_LOG_LOCATION = newrelic_apm_log_location()

LOGS_OWNER = 'root'

TOMCAT_OWNER = node['tomcat']['owner']
TOMCAT_GROUP = node['tomcat']['group']

directory NEWRELIC_APM_DESTINATION do
  mode '0755'
  recursive true
end

directory NEWRELIC_APM_LOG_LOCATION do
  owner LOGS_OWNER
  group TOMCAT_GROUP
  mode '0775'
  recursive true
end

artifactory_artifact NEWRELIC_APM_JAR_PATH do
  artifactory_url 'https://artifactory.sophos-tools.com/artifactory'
  repository 'maven'
  repository_path "com/newrelic/agent/java/#{NEWRELIC_APM_ARTIFACT_ID}/#{NEWRELIC_APM_VERSION}/#{NEWRELIC_APM_JAR_NAME}"
end
