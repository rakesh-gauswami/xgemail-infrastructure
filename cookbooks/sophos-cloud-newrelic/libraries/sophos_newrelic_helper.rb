#
# Cookbook Name:: sophos-cloud-newrelic
# Library:: sophos_newrelic_helper
#
# Copyright:: 2022, Sophos 2022, All Rights Reserved.

require 'open3'

module SophosCentral
  module SophosNewrelicHelper

    def newrelic_run_or_raise (*argv)
      stdout, status = Open3.capture2(*argv)
      if !status.success? then
        raise Exception.new "command failed: #{argv.join(' ')}"
      end
      return stdout
    end

    def newrelic_aws_secret_string (secret_id)
      return newrelic_run_or_raise(
        'aws', 'secretsmanager', 'get-secret-value',
        '--region', newrelic_sophos_region(),
        '--secret-id', secret_id,
        '--query', 'SecretString',
        '--output', 'text'
      )
    end

    def newrelic_license ()
      license_key = newrelic_aws_secret_string('/central/newrelic/license')
      return license_key.nil? ? "" : license_key
    end

    def newrelic_sophos_application_name ()
      return "#{node['sophos_cloud']['cluster']}"
    end

    def newrelic_sophos_account_name ()
      return "#{node['sophos_cloud']['environment']}"
    end

    def newrelic_sophos_region ()
      return "#{node['sophos_cloud']['region']}"
    end

    def newrelic_display_name ()
      return "#{node['sophos_cloud']['cluster']}-#{node['ec2']['instance_id']}-#{node['sophos_cloud']['environment']}"
    end

    def newrelic_infra_bin_location()
      return "#{node['newrelic']['infra']['bin_location']}"
    end

    def newrelic_infra_conf_location()
      return "#{node['newrelic']['infra']['conf_location']}"
    end

    def newrelic_infra_conf_file ()
      return "#{newrelic_infra_conf_location()}/newrelic-infra.yml"
    end

    def newrelic_infra_enabled ()
      return "#{node['newrelic']['enabled']}"
    end

    def newrelic_infra_log_file ()
      return "#{newrelic_infra_log_location()}/newrelic-infra.log"
    end

    def newrelic_infra_log_location ()
      return "#{node['newrelic']['infra']['log_location']}"
    end

    def newrelic_infra_network_metrics_sample_rate ()
      return "#{node['newrelic']['infra']['network_metrics']['sample_rate']}"
    end

    def newrelic_infra_process_metrics_enabled ()
      return "#{node['newrelic']['infra']['process_metrics']['enable']}"
    end

    def newrelic_infra_process_metrics_sample_rate ()
      return "#{node['newrelic']['infra']['process_metrics']['sample_rate']}"
    end

    def newrelic_infra_storage_metrics_sample_rate ()
      return "#{node['newrelic']['infra']['storage_metrics']['sample_rate']}"
    end

    def newrelic_infra_system_metrics_sample_rate ()
      return "#{node['newrelic']['infra']['system_metrics']['sample_rate']}"
    end

    def newrelic_infra_agent_rpm_name ()
      return "newrelic-infra-#{node['newrelic']['infra']['version']}.x86_64"
    end

  end
end

Chef::Recipe.include( SophosCentral::SophosNewrelicHelper )
Chef::Resource.include( SophosCentral::SophosNewrelicHelper )
