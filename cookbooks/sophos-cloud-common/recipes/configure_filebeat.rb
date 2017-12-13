#
# Cookbook Name:: sophos-cloud-common
# Recipe:: configure_filebeat
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute

if node['sophos_cloud'].key?('logzio_poc') and node['sophos_cloud']['logzio_poc'].downcase == 'true'

  include_recipe 'sophos-cloud-common::common_docker'

  docker_image 'prima/filebeat' do
    action :pull
  end

  directory '/etc/logzio' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  cookbook_file "/etc/logzio/logz.io.crt" do
    source "logz.io.crt"
  end

  template "filebeat.yml" do
    path "/etc/filebeat.yml"
    source "filebeat.yml.erb"
    mode "0644"
    owner "root"
    group "root"
    variables(
        :sophos_logs       => node['sophos_cloud_common']['configure_logstash_forwarder']['sophos_log_path'],
        :region            => node['sophos_cloud']['region'],
        :branch            => node['sophos_cloud']['branch'],
        :env               => node['sophos_cloud']['environment'],
        :app               => node['sophos_cloud']['application_name'],
        :instance_id       => node['sophos_cloud']['instance_id']
    )
  end

  def add_mount(path, mnt_point)
    "#{path}:#{mnt_point}:ro"
  end

  filebeat_mounts = ['/etc/logzio:/etc/logzio/:ro', '/etc/filebeat.yml:/filebeat.yml:ro']

  filebeat_mounts << add_mount("/data",
                               "/data")
  filebeat_mounts << add_mount("/var/log",
                                "/var/log")

  docker_container 'filebeat' do
    repo 'prima/filebeat'
    volumes filebeat_mounts
    action :run_if_missing
    restart_policy 'always'
  end

end
