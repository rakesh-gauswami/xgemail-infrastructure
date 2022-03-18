#
# Cookbook Name:: sophos-cloud-common
# Library:: sophos-cloud-common_helper
#
# Copyright:: 2019, Sophos 2019, All Rights Reserved.

module SophosCentral
  module SophosTomcatHelper

    def application_create_truststore_command ()
      return "#{node['sophos_server']['scripts_dir']}/create-application-truststore.sh"
    end

    def application_properties_file ()
      return "#{catalina_conf_dir()}/application.properties"
    end

    def application_truststore_file ()
      return "#{catalina_conf_dir()}/#{node['app']['security']['truststore_file']}"
    end

    def application_truststore_password_file ()
      return "#{catalina_conf_dir()}/application-truststore-password.txt"
    end

    def application_ssl_properties_file ()
      return "#{catalina_conf_dir()}/ssl.properties"
    end

    def catalina_base ()
      return "/var/lib/tomcats/#{node['tomcat']['service_sub_name']}"
    end

    def catalina_conf_dir ()
      return "#{catalina_base()}/conf"
    end

    def catalina_properties_file ()
      return "#{catalina_conf_dir()}/catalina.properties"
    end

    def catalina_webapp_root_dir ()
      return "#{catalina_webapps_dir()}/#{catalina_webapp_root_name()}"
    end

    def catalina_webapp_root_name ()
      return "#{node['tomcat']['war_artifact_id']}-#{node['tomcat']['war_version']}"
    end

    def catalina_webapps_dir ()
      return "#{catalina_base()}/webapps"
    end

    def catalina_WEB_INF_conf_dir ()
      return "#{catalina_WEB_INF_dir()}/conf"
    end

    def catalina_WEB_INF_dir ()
      return "#{catalina_webapp_root_dir()}/WEB-INF"
    end

    def cmd_configuration_file ()
      return "#{node['cmd']['destination']}"
    end

    def cmd_enabled()
      cmd_json = "#{catalina_conf_dir()}/cmd.json"
      is_enabled = false
      if File.exist?(cmd_json)
        parsed_json = server_base_parse_json_file(cmd_json)
        is_enabled = parsed_json['cmd']['is_enabled']
      end
      return is_enabled
    end

    def dynatrace_script_name ()
      return "#{dynatrace_versioned_artifact()}.sh"
    end

    def dynatrace_versioned_artifact ()
      return "#{node['dynatrace']['artifact_id']}-#{node['dynatrace']['version']}"
    end

    def resolve_allowed_origins()
      File.open(application_properties_file()) do |f|
        f.each_line do |line|
          if line.start_with?('sophos.allowed.origins')
            line.chomp!
            return line
          end
        end
      end

      return nil
    end

    def newrelic_apm_conf_file ()
      return "#{newrelic_apm_destination()}/newrelic.yml"
    end

    def newrelic_apm_destination ()
      return "#{node['newrelic']['apm']['destination']}"
    end

    def newrelic_apm_enabled (params = newrelic_conf_parameters())

      enabled = params.dig('newrelic', 'apm', 'is_enabled')

      if (enabled.nil?)
        enabled = params.dig('newrelic', 'is_enabled')
      end
      return enabled.nil? ? false : enabled
    end

    def newrelic_apm_jar_name ()
      return "#{newrelic_apm_versioned_artifact()}.jar"
    end

    def newrelic_apm_jar_path ()
      return "#{newrelic_apm_destination()}/#{newrelic_apm_jar_name()}"
    end

    def newrelic_apm_java_opts ()
      ret_val = []

      configuration_file = newrelic_apm_conf_file()

      return ret_val unless File.file?(configuration_file)

      ret_val << "-javaagent:#{newrelic_apm_jar_path()}"

      return ret_val
    end

    def newrelic_apm_log_location ()
      return "#{node['newrelic']['apm']['log_location']}"
    end

    def newrelic_apm_versioned_artifact ()
      return "#{node['newrelic']['apm']['artifact_id']}-#{node['newrelic']['apm']['version']}"
    end

    def newrelic_conf_parameters()

      params = Hash.new
      conf_dir = catalina_conf_dir()
      config_file = "#{conf_dir}/newrelic.json"

      if ::File.exist?(config_file)
        params = server_base_parse_json_file(config_file)
      end
      return params
    end

    def newrelic_infra_bin_location()
      return "#{node['newrelic']['infra']['bin_location']}"
    end

    def newrelic_infra_flex_conf_file()
      return "#{newrelic_infra_conf_location()}/integrations.d/newrelic-flex.yml"
    end

    def newrelic_infra_conf_location()
      return "#{node['newrelic']['infra']['conf_location']}"
    end

    def newrelic_infra_conf_file ()
      return "#{newrelic_infra_conf_location()}/newrelic-infra.yml"
    end

    def newrelic_infra_enabled (params = newrelic_conf_parameters())

      enabled = params.dig('newrelic', 'infra', 'is_enabled')

      if (enabled.nil?)
        enabled = params.dig('newrelic', 'is_enabled')
      end
      return enabled.nil? ? false : enabled
    end

    def newrelic_infra_integration_conf_location ()
      return "#{node['newrelic']['infra']['integrations']['conf_location']}"
    end

    def newrelic_infra_jmx_collection_files_arr (app_name)

      all_files = Array.new
      common_files = node['newrelic']['infra']['jmx']['collection_files']['names']

      unless (common_files.nil?)
        all_files.concat(common_files)
      end

      collection_files_path = node['newrelic']['infra']['jmx']['collection_files']['location']
      #get all collection files for app name
      app_collection_files = Dir.glob(collection_files_path + "/#{app_name}*")
      #remove the path from the collection file names
      app_collection_files.collect! do |e|
          e.delete_prefix("#{collection_files_path}/")
      end

      all_files.concat(app_collection_files)
      return all_files
    end

    def newrelic_infra_jmx_collection_files (app_name, project_name)

      all_files = Array.new
      common_files = node['newrelic']['infra']['jmx']['collection_files']['names']

      unless (common_files.nil?)
        all_files.concat(common_files)
      end

      # Assume that 1 or both of the following mbean files exists for each SOA service,
      # unless we want to maintain a hash detailing what exact mbean collection files correspond
      # to each SOA service.
      #
      # These files will get filtered as-necessary when rendering the JMX configuration template.
      #
      # Note that not all the service files exist yet. They are a work-in-progress.
      all_files.append("#{app_name}-metrics.yml")
      if ("#{project_name}".include? "-")
          all_files.append("#{project_name}-metrics.yml");
      else
          all_files.append("#{app_name}-#{project_name}-metrics.yml");
      end

      base_dir = newrelic_infra_jmx_collection_files_location()

      all_files = all_files.map { |collection_file| "#{base_dir}/#{collection_file}" }

      return all_files
    end

    def newrelic_infra_jmx_collection_files_location ()
      return "#{node['newrelic']['infra']['jmx']['collection_files']['location']}"
    end

    def newrelic_infra_jmx_conf_file ()
      return "#{newrelic_infra_integration_conf_location()}/jmx-config.yml"
    end

    def newrelic_infra_jmx_enabled (params = newrelic_conf_parameters())

      enabled = params.dig('newrelic', 'infra', 'jmx', 'enabled')

      return enabled.nil? ? false : enabled
    end

    def newrelic_infra_jmx_sample_rate (params = newrelic_conf_parameters())

      rate = params.dig('newrelic', 'infra', 'jmx', 'sample_rate')

      return rate.nil? ? "#{node['newrelic']['infra']['jmx']['sample_rate']}s" : "#{rate}s"
    end

    def newrelic_infra_log_file ()
      return "#{newrelic_infra_log_location()}/newrelic-infra.log"
    end

    def newrelic_infra_log_fwd_conf_file ()
      return "#{newrelic_infra_log_fwd_conf_location()}/newrelic-infra-log-forwarding.yml"
    end

    def newrelic_infra_log_fwd_conf_location ()
      return "#{node['newrelic']['infra']['log_forwarding']['conf_location']}"
    end

    def newrelic_infra_log_fwd_enabled (params = newrelic_conf_parameters())

      enabled = params.dig('newrelic', 'infra', 'is_log_fwding_enabled')

      if (enabled.nil?)
        enabled = params.dig('newrelic', 'is_log_fwding_enabled')
      end
      return enabled.nil? ? false : enabled
    end

    def newrelic_infra_log_location ()
      return "#{node['newrelic']['infra']['log_location']}"
    end

    def newrelic_license (params = newrelic_conf_parameters())

      license_key = params['newrelic']['license_key']

      return license_key.nil? ? "" : license_key
    end

    def newrelic_infra_network_metrics_sample_rate (params = newrelic_conf_parameters())

      rate = params.dig('newrelic', 'infra', 'network_metrics', 'sample_rate')

      return rate.nil? ? node['newrelic']['infra']['network_metrics']['sample_rate'] : rate
    end

    def newrelic_infra_process_metrics_enabled (params = newrelic_conf_parameters())

      enable = params.dig('newrelic', 'infra', 'process_metrics', 'enable')

      return enable.nil? ? node['newrelic']['infra']['process_metrics']['enable'] : enable
    end

    def newrelic_infra_process_metrics_naming_patterns (params = newrelic_conf_parameters())

      patterns = params.dig('newrelic', 'infra', 'process_metrics', 'naming_patterns')

      return patterns.nil? ? node['newrelic']['infra']['process_metrics']['naming_patterns'] : patterns
    end

    def newrelic_infra_process_metrics_sample_rate (params = newrelic_conf_parameters())

      rate = params.dig('newrelic', 'infra', 'process_metrics', 'sample_rate')

      return rate.nil? ? node['newrelic']['infra']['process_metrics']['sample_rate'] : rate
    end

    def newrelic_infra_storage_metrics_sample_rate (params = newrelic_conf_parameters())

      rate = params.dig('newrelic', 'infra', 'storage_metrics', 'sample_rate')

      return rate.nil? ? node['newrelic']['infra']['storage_metrics']['sample_rate'] : rate
    end

    def newrelic_infra_system_metrics_sample_rate (params = newrelic_conf_parameters())

      rate = params.dig('newrelic', 'infra', 'system_metrics', 'sample_rate')

      return rate.nil? ? node['newrelic']['infra']['system_metrics']['sample_rate'] : rate
    end

    def newrelic_tags_sophos_project ()
      return "#{node['newrelic']['tags']['sophos_project']}"
    end

    def newrelic_prometheus_destination ()
      return "#{node['newrelic']['infra']['prometheus']['destination']}"
    end

    def newrelic_prometheus_conf_file ()
      return "#{newrelic_infra_prometheus_jmx_conf_file_location()}/jmx-exporter.yml"
    end

    def newrelic_prometheus_jar_name ()
      return "jmx_prometheus_javaagent-#{newrelic_prometheus_versioned_artifact()}.jar"
    end

    def newrelic_prometheus_jar_path ()
      return "#{newrelic_prometheus_destination()}/#{newrelic_prometheus_jar_name()}"
    end

    def newrelic_nri_jmx_rpm_name ()
       return "nri-jmx-#{node['newrelic']['infra']['jmx']['version']}.x86_64"
    end

    def newrelic_nrjmx_rpm_name ()
       return "nrjmx-#{node['newrelic']['infra']['nrjmx']['version']}.x86_64"
    end

    def newrelic_infra_agent_rpm_name ()
      return "newrelic-infra-#{node['newrelic']['infra']['version']}.x86_64"
    end

    def newrelic_prometheus_java_opts ()
      ret_val = []
      flex_configuration_file = newrelic_infra_flex_conf_file()
      prometheus_configuration_file = newrelic_infra_prometheus_jmx_conf_file()

      return ret_val unless File.file?(flex_configuration_file) && File.file?(prometheus_configuration_file)

      ret_val << "-javaagent:#{newrelic_prometheus_jar_path()}=#{newrelic_infra_prometheus_port()}:#{newrelic_infra_prometheus_jmx_conf_file()}"

      return ret_val
    end

    def newrelic_infra_prometheus_port ()
      return "#{node['newrelic']['infra']['prometheus']['port']}"
    end

    def newrelic_prometheus_versioned_artifact ()
      return "#{node['newrelic']['infra']['prometheus']['version']}"
    end

    def newrelic_infra_prometheus_jmx_conf_file()
      return "#{newrelic_infra_prometheus_jmx_conf_file_location()}/jmx-exporter-config.yml"
    end

    def newrelic_infra_prometheus_jmx_conf_file_location()
      return "#{node['newrelic']['infra']['prometheus']['jmx']['conf_location']}"
    end

    def newrelic_infra_jmx_prometheus_enabled (params = newrelic_conf_parameters())
      enabled = params.dig('newrelic', 'infra', 'jmx_prometheus', 'enabled')

      return enabled.nil? ? false : enabled
    end

    def sealights_buildSessionId_file ()
      return "#{sealights_destination()}/buildSessionId.txt"
    end

    def sealights_destination ()
      return "#{node['sealights']['destination']}"
    end

    def sealights_jar_name ()
      return "#{sealights_versioned_artifact()}.jar"
    end

    def sealights_jar_path ()
      return "#{sealights_destination()}/#{sealights_jar_name()}"
    end

    def sealights_java_opts ()
      ret_val = []

      buildSessionId_file = sealights_buildSessionId_file()

      return ret_val unless File.file?(buildSessionId_file)

      ret_val << "-javaagent:#{sealights_jar_path()}"
      ret_val << "-Dsl.labId=#{node['sealights']['lab_id']}"
      ret_val << "-Dsl.tokenFile=#{sealights_token_file()}"
      ret_val << "-Dsl.buildSessionIdFile=#{buildSessionId_file}"
      ret_val << "-Dsl.log.enabled=#{node['sealights']['log_enabled']}"
      ret_val << "-Dsl.log.folder=#{node['sealights']['log_location']}"
      ret_val << "-Dsl.log.level=#{node['sealights']['log_level']}"
      ret_val << "-Dsl.log.toFile=#{node['sealights']['log_to_file']}"

      return ret_val
    end

    def sealights_token_file ()
      return "#{sealights_destination()}/#{node['sealights']['token_file']}"
    end

    def sealights_versioned_artifact ()
      return "#{node['sealights']['artifact_id']}-#{node['sealights']['version']}"
    end

    def sophos_legacy_config_path ()
      return '/usr/local/etc/sophos'
    end

    def sqreen_conf_file ()
      return "#{catalina_conf_dir()}/sqreen.json"
    end

    def sqreen_destination ()
      return "#{node['sqreen']['destination']}"
    end

    def sqreen_jar_name ()
      return "#{sqreen_versioned_artifact()}.jar"
    end

    def sqreen_jar_path ()
      return "#{sqreen_destination()}/#{sqreen_jar_name()}"
    end

    def sqreen_versioned_artifact ()
      return "#{node['sqreen']['artifact_id']}-#{node['sqreen']['version']}"
    end

    def sqreen_token()
      sqreen_json = sqreen_conf_file()
      sqreen_token = ""
      if File.exist?(sqreen_json)
        parsed_json = server_base_parse_json_file(sqreen_json)
        sqreen_token = parsed_json['sqreen']['sqreen_token']
      end
      return sqreen_token
    end

    def sqreen_appname()
      return "#{node['sqreen']['appname']}"
    end

    def sqreen_java_opts ()
      ret_val = []
      sqreen_json = sqreen_conf_file()
      sqreen_is_enabled = false
      if File.exist?(sqreen_json)
        parsed_json = server_base_parse_json_file(sqreen_json)
        sqreen_is_enabled = parsed_json['sqreen']['is_enabled']
      end

      if (sqreen_is_enabled)
        ret_val << "-javaagent:#{sqreen_jar_path()}"
        ret_val << "-Dsqreen.token=#{sqreen_token()}"
        ret_val << "-Dsqreen.app_name=#{sqreen_appname()}"
      end
      return ret_val
    end

    def tomcat_akm_bundle_source_name ()
      app_name_override = node['tomcat']['crypto']['akm']['source_override']

      if app_name_override.nil?
        return server_base_application_name()
      end

      return app_name_override
    end

    def tomcat_service_name ()
      return "tomcat@#{node['tomcat']['service_sub_name']}"
    end

    def tomcat_start_java_opts_file ()
      return "#{catalina_conf_dir()}/start-java-opts.conf"
    end

    def tomcat_start_java_opts_file_template ()
      return "#{tomcat_start_java_opts_file()}.erb"
    end

    def tomcat_config_bucket ()
      config_bucket_override = node['tomcat']['config_bucket_override']

      unless config_bucket_override.nil?
        return config_bucket_override
      end

      instance_tags_config_bucket_override = node['instance_tags']['config_bucket']

      unless instance_tags_config_bucket_override.nil?
        return instance_tags_config_bucket_override
      end

      return "central-configs-#{server_base_account_name()}-#{server_base_region()}"
    end

    def tomcat_config_bucket_region ()
      config_bucket_region_override = node['tomcat']['config_bucket_region_override']

      unless config_bucket_region_override.nil?
        return config_bucket_region_override
      end

      return server_base_region()
    end

    def tomcat_configuration_branch ()
      ret_val = node['tomcat']['configuration_branch']

      unless ret_val.nil?
        return ret_val
      end

      # Default to server_base_branch_name
      return server_base_branch_name()
    end

    def tomcat_cipher_spec()
      return node['tomcat']['connector']['cipher_spec']
    end

    def tomcat_compressible_mime_types()
      return node['tomcat']['connector']['compressible_mime_types']
    end

    def tomcat_executor_name()
      return node['tomcat']['executor_name']
    end

    def tomcat_create_keystore_command ()
      return "#{node['sophos_server']['scripts_dir']}/create-tomcat-keystore.sh"
    end

    def tomcat_keystore_file ()
      return "#{catalina_conf_dir()}/#{node['tomcat']['security']['keystore_file']}"
    end

    def tomcat_keystore_password_file ()
      return "#{catalina_conf_dir()}/tomcat-keystore-password.txt"
    end

    def tomcat_create_truststore_command ()
      return "#{node['sophos_server']['scripts_dir']}/create-tomcat-truststore.sh"
    end

    def tomcat_truststore_file ()
      return "#{catalina_conf_dir()}/#{node['tomcat']['security']['truststore_file']}"
    end

    def tomcat_truststore_password_file ()
      return "#{catalina_conf_dir()}/tomcat-truststore-password.txt"
    end

  end
end

Chef::Recipe.include( SophosCentral::SophosTomcatHelper )
Chef::Resource.include( SophosCentral::SophosTomcatHelper )
