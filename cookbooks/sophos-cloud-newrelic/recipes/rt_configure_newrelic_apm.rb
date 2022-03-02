#
# Cookbook:: sophos_tomcat
# Recipe:: rt_configure_newrelic_apm
#
# Copyright:: 2020, Sophos 2020, All Rights Reserved.

APP_NAME = server_base_application_name()

AWS_ACCOUNT = server_base_account_name()
AWS_REGION = server_base_region()

NEWRELIC_APM_CONFIG_FILE = newrelic_apm_conf_file()
NEWRELIC_APM_LOG_LOCATION = newrelic_apm_log_location()
NEWRELIC_APM_TEMPLATE = "newrelic.yml.erb"

NEWRELIC_TAGS_SOPHOS_PROJECT = newrelic_tags_sophos_project()

CONFIG_OWNER = 'root'
TOMCAT_GROUP = node['tomcat']['group']

template NEWRELIC_APM_CONFIG_FILE do
  source NEWRELIC_APM_TEMPLATE
  mode "0640"
  owner CONFIG_OWNER
  group TOMCAT_GROUP
  variables (
    lazy {
      {
        application_name: APP_NAME,
        license_key: newrelic_license(),
        log_file_name: 'newrelic.log',
        log_file_path: NEWRELIC_APM_LOG_LOCATION,
        sophos_env: AWS_ACCOUNT,
        sophos_region: AWS_REGION,
        sophos_project: NEWRELIC_TAGS_SOPHOS_PROJECT,
        sophos_app: APP_NAME
      }
    }
  )
  only_if {
    newrelic_apm_enabled()
  }
end
