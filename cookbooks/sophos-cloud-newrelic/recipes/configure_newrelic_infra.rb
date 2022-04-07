#
# Cookbook:: sophos-cloud-newrelic
# Recipe:: configure_newrelic_infra
#
# Copyright:: 2022, Sophos 2022, All Rights Reserved.

APP_NAME = newrelic_sophos_application_name()
AWS_ACCOUNT = newrelic_sophos_account_name()
AWS_REGION = newrelic_sophos_region()
DISPLAY_NAME = newrelic_display_name()

NEWRELIC_INFRA_CONF_FILE = newrelic_infra_conf_file()
NEWRELIC_INFRA_LOG_FILE = newrelic_infra_log_file()
NEWRELIC_INFRA_SERVICE = 'newrelic-infra'

SYSTEMD_UNIT_RESOURCE = "systemd_unit[#{NEWRELIC_INFRA_SERVICE}]"

NEWRELIC_GROUP = node['newrelic']['group']

ruby_block 'Get New Relic License' do
  block do
    node.run_state['new_relic_license_key'] = newrelic_license()
  end
end

# Note that the NewRelic yum installation by default sets up the newrelic-infra agent with systemd
systemd_unit NEWRELIC_INFRA_SERVICE do
  action :nothing
end

template NEWRELIC_INFRA_CONF_FILE do
  source 'newrelic-infra.yml.erb'
  mode '0640'
  owner 'root'
  group 'root'

  variables (
      lazy {
        {
          sophos_app: APP_NAME,
          sophos_env: AWS_ACCOUNT,
          sophos_region: AWS_REGION,
          sophos_project: 'xgemail',
          display_name: DISPLAY_NAME,
          log_file_path: NEWRELIC_INFRA_LOG_FILE,
          license_key: node.run_state['new_relic_license_key'],
          enable_process_metrics: newrelic_infra_process_metrics_enabled(),
          processing_metrics_naming_patterns: newrelic_infra_process_metrics_naming_patterns(),
          metrics_process_sample_rate: newrelic_infra_process_metrics_sample_rate(),
          metrics_network_sample_rate: newrelic_infra_network_metrics_sample_rate(),
          metrics_storage_sample_rate: newrelic_infra_storage_metrics_sample_rate(),
          metrics_system_sample_rate: newrelic_infra_system_metrics_sample_rate()
        }
      }
    )

  notifies :enable, SYSTEMD_UNIT_RESOURCE, :immediately
  notifies :start, SYSTEMD_UNIT_RESOURCE, :immediately

  only_if {
    newrelic_infra_enabled()
  }
end
