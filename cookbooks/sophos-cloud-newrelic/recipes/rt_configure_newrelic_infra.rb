#
# Cookbook:: sophos_tomcat
# Recipe:: rt_configure_newrelic_infra
#
# Copyright:: 2020, Sophos 2020, All Rights Reserved.

APP_NAME = server_base_application_name()
PROJECT_NAME = server_base_project_name()

AWS_ACCOUNT = server_base_account_name()
AWS_REGION = server_base_region()

CONFIG_OWNER = 'root'

NEWRELIC_INFRA_CONF_FILE = newrelic_infra_conf_file()
NEWRELIC_INFRA_CONF_FILE_TPL = "newrelic-infra.yml.erb"
NEWRELIC_INFRA_LOG_FILE = newrelic_infra_log_file()
NEWRELIC_INFRA_LOG_FWD_CONF_FILE = newrelic_infra_log_fwd_conf_file()
NEWRELIC_INFRA_LOG_FWD_CONF_FILE_TPL = "newrelic-infra-log-forwarding.yml.erb"
NEWRELIC_INFRA_JMX_COLLECTION_FILES_LOCATION = newrelic_infra_jmx_collection_files_location()
NEWRELIC_INFRA_JMX_CONF_FILE = newrelic_infra_jmx_conf_file()
NEWRELIC_INFRA_RUBY_BLOCK = "jmx-collection-files-setup"
NEWRELIC_INFRA_JMX_CONF_RESOURCE = "ruby_block[#{NEWRELIC_INFRA_RUBY_BLOCK}]"
NEWRELIC_INFRA_PROMETHEUS_JMX_CONF_FILE = newrelic_infra_prometheus_jmx_conf_file()
NEWRELIC_INFRA_PROMETHEUS_JMX_CONF_FILE_TPL = "newrelic-infra-prometheus-jmx-config.yml.erb"
NEWRELIC_INFRA_FLEX_CONF_FILE = newrelic_infra_flex_conf_file()
NEWRELIC_INFRA_FLEX_CONF_FILE_TPL = "newrelic-flex-config.yml.erb"
NEWRELIC_INFRA_SERVICE = "newrelic-infra"
NEWRELIC_TAGS_SOPHOS_PROJECT = newrelic_tags_sophos_project()
PROMETHEUS_PORT = newrelic_infra_prometheus_port()

SYSTEMD_UNIT_RESOURCE = "systemd_unit[#{NEWRELIC_INFRA_SERVICE}]"

TOMCAT_GROUP = node['tomcat']['group']

template NEWRELIC_INFRA_CONF_FILE do

  source NEWRELIC_INFRA_CONF_FILE_TPL
  mode "0640"
  owner CONFIG_OWNER
  group TOMCAT_GROUP

  variables (
      lazy {
        params = newrelic_conf_parameters()
        {
          sophos_env: AWS_ACCOUNT,
          sophos_region: AWS_REGION,
          sophos_project: NEWRELIC_TAGS_SOPHOS_PROJECT,
          sophos_app: APP_NAME,
          log_file_path: NEWRELIC_INFRA_LOG_FILE,
          license_key: newrelic_license(params),
          enable_process_metrics: newrelic_infra_process_metrics_enabled(params),
          processing_metrics_naming_patterns: newrelic_infra_process_metrics_naming_patterns(params),
          metrics_process_sample_rate: newrelic_infra_process_metrics_sample_rate(params),
          metrics_network_sample_rate: newrelic_infra_network_metrics_sample_rate(params),
          metrics_storage_sample_rate: newrelic_infra_storage_metrics_sample_rate(params),
          metrics_system_sample_rate: newrelic_infra_system_metrics_sample_rate(params)
        }
      }
    )

  notifies :enable, SYSTEMD_UNIT_RESOURCE, :immediately
  notifies :start, SYSTEMD_UNIT_RESOURCE, :immediately

  only_if {
    newrelic_infra_enabled()
  }
end

remote_directory NEWRELIC_INFRA_JMX_COLLECTION_FILES_LOCATION do
  source 'jmx'
  mode '0640'
  owner CONFIG_OWNER
  group TOMCAT_GROUP

  action :create

  notifies :create, NEWRELIC_INFRA_JMX_CONF_RESOURCE, :immediately
  only_if {
      newrelic_infra_jmx_enabled()
    }
end

ruby_block NEWRELIC_INFRA_RUBY_BLOCK do
    block do
        interval = newrelic_infra_jmx_sample_rate()
        sophos_env = AWS_ACCOUNT
        sophos_region = AWS_REGION
        sophos_project = NEWRELIC_TAGS_SOPHOS_PROJECT
        sophos_app = APP_NAME
        for jmx_collection_file in newrelic_infra_jmx_collection_files_arr(APP_NAME) do
            newrelic_jmx_conf_file = newrelic_infra_integration_conf_location() + "/jmx_config_" + jmx_collection_file
            File.write(newrelic_jmx_conf_file,
                "integrations:\n" +
                "  - name: nri-jmx\n" +
                "    integration_name: com.newrelic.jmx\n" +
                "    command: all_data\n" +
                "    arguments:\n" +
                "      jmx_port: 1099\n" +
                "      collection_files: #{newrelic_infra_jmx_collection_files_location()}/#{jmx_collection_file}\n" +
                "      interval: #{interval}\n" +
                "    labels:\n" +
                "      SophosEnv: #{sophos_env}\n" +
                "      SophosRegion: #{sophos_region}\n" +
                "      SophosProject: #{sophos_project}\n" +
                "      SophosApp: #{sophos_app}")
        end
    end
    action :nothing
end

template NEWRELIC_INFRA_PROMETHEUS_JMX_CONF_FILE do

  source NEWRELIC_INFRA_PROMETHEUS_JMX_CONF_FILE_TPL
  mode "0640"
  owner CONFIG_OWNER
  group TOMCAT_GROUP

  variables(
      lazy {
        {
          sophos_env: AWS_ACCOUNT,
          sophos_region: AWS_REGION,
          sophos_project: NEWRELIC_TAGS_SOPHOS_PROJECT,
          sophos_app: APP_NAME
        }
      }
    )

  only_if {
    newrelic_infra_jmx_prometheus_enabled() && !newrelic_infra_jmx_enabled()
  }
end

template NEWRELIC_INFRA_FLEX_CONF_FILE do

  source NEWRELIC_INFRA_FLEX_CONF_FILE_TPL
  mode "0640"
  owner CONFIG_OWNER
  group TOMCAT_GROUP

  variables(
    lazy {
      {
        sophos_env: AWS_ACCOUNT,
        sophos_region: AWS_REGION,
        sophos_project: NEWRELIC_TAGS_SOPHOS_PROJECT,
        sophos_app: APP_NAME,
        prometheus_port: PROMETHEUS_PORT
      }
    }
  )
  only_if {
    newrelic_infra_jmx_prometheus_enabled() && !newrelic_infra_jmx_enabled()
  }
end

template NEWRELIC_INFRA_LOG_FWD_CONF_FILE do

  source NEWRELIC_INFRA_LOG_FWD_CONF_FILE_TPL
  mode "0640"
  owner CONFIG_OWNER
  group TOMCAT_GROUP

  variables(
    sophos_env: AWS_ACCOUNT,
    sophos_region: AWS_REGION,
    sophos_project: NEWRELIC_TAGS_SOPHOS_PROJECT,
    sophos_app: APP_NAME
  )

  only_if {
    newrelic_infra_log_fwd_enabled()
  }
end

# Note that the NewRelic yum installation by default sets up the newrelic-infra agent with systemd
systemd_unit NEWRELIC_INFRA_SERVICE do
  action :nothing
end
