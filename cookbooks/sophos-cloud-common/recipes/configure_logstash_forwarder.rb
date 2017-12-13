#
# Cookbook Name:: sophos-cloud-common
# Recipe:: configure_logstash_forwarder
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute

# The logstash forwarder uses the key to encrypt data transfer to the logstash server
# The logstash server uses the the same key-pair to decrypt log data
# The key pairs are different from region to region and differ also from account to account
# If no logstash key available - skip installation

# default:=/tmp/sophos

if node['sophos_cloud']['logzio_poc'].downcase != 'true'
  tmp_certificate_download_path = "#{node['sophos_cloud']['tmp']}/certificates"

  directory tmp_certificate_download_path do
    mode "0755"
    owner "root"
    group "root"
    recursive true
  end

  directory node['sophos_cloud']['local_key_path'] do
    mode "0755"
    owner "root"
    group "root"
    recursive true
  end

  logstash_vpc_name=node['sophos_cloud']['vpc_name']

  if node['sophos_cloud_common']['configure_logstash_forwarder']['should_use_default_logstash_vpc_name']
    logstash_vpc_name='CloudStation'
  end

  logstash_connection_file = "#{node['sophos_cloud']['environment']}-connection-logstash-forwarder.tar.gz"
  logstash_connection_path = "cloud-#{node['sophos_cloud']['environment']}-connections/#{node['sophos_cloud']['region']}/#{logstash_vpc_name}"
  logstash_key_filename = "#{node['sophos_cloud']['environment']}-connection-logstash-forwarder"

  if node['sophos_cloud_common']['configure_logstash_forwarder']['should_use_default_logstash_vpc_name']
    log_vpc_location = "cloudstation"
  else
    log_vpc_location = node['sophos_cloud']['vpc_name'].downcase
  end

  logstash_local_connection_file_path = "#{tmp_certificate_download_path}/#{logstash_connection_file}"
  logstash_local_key_filename = "logstash-forwarder"

  logstash_server_address = "lgstshshipper"
  logstash_server_address << ".#{log_vpc_location}"
  logstash_server_address << ".#{node['ec2']['placement_availability_zone'].chop}".downcase
  logstash_server_address << ".#{node['sophos_cloud']['environment']}".downcase
  logstash_server_address << ".hydra.sophos.com:5000"

  file logstash_local_connection_file_path do
    action :delete
  end

  log "Download from S3://#{logstash_connection_path}/#{logstash_connection_file} to #{tmp_certificate_download_path}" do
    level :info
  end


  bash "download_existing_logstash_keypair_and_cert" do
    user "root"
    cwd "#{tmp_certificate_download_path}"
    code <<-EOH
      aws configure set default.s3.signature_version s3v4
      aws --region us-west-2 s3 cp s3://#{logstash_connection_path}/#{logstash_connection_file}  #{tmp_certificate_download_path} || true
    EOH
  end

  bash "install_logstash_forwarder_keys" do
    user "root"
    cwd "#{tmp_certificate_download_path}"
    only_if { ::File.exists?(logstash_local_connection_file_path) }
    code <<-EOH
      tar -xzvf #{logstash_local_connection_file_path} --transform='s\/.*\\/\/\/'
    EOH
  end

  # Using bash until I can find a way to stop remote file from logging the file contents
  bash "move_cert_and_key" do
    user "root"
    cwd "/tmp"
    code <<-EOH
          mv #{tmp_certificate_download_path}/#{logstash_key_filename}.crt #{node['sophos_cloud']['local_cert_path']}/#{logstash_local_key_filename}.crt
          chmod 0444 #{node['sophos_cloud']['local_cert_path']}/#{logstash_local_key_filename}.crt
          chown root:root #{node['sophos_cloud']['local_cert_path']}/#{logstash_local_key_filename}.crt

          mv #{tmp_certificate_download_path}/#{logstash_key_filename}.key #{node['sophos_cloud']['local_key_path']}/#{logstash_local_key_filename}.key
          chmod 0440 #{node['sophos_cloud']['local_key_path']}/#{logstash_local_key_filename}.key
          chown root:root #{node['sophos_cloud']['local_key_path']}/#{logstash_local_key_filename}.key
    EOH
    only_if { ::File.exists?(logstash_local_connection_file_path) }
  end

  file "#{tmp_certificate_download_path}/#{logstash_key_filename}.crt" do
    action :delete
    only_if { ::File.exists?(logstash_local_connection_file_path) }
  end

  file "#{tmp_certificate_download_path}/#{logstash_key_filename}.key" do
    action :delete
    only_if { ::File.exists?(logstash_local_connection_file_path) }
  end

  file logstash_local_connection_file_path do
    action :delete
    only_if { ::File.exists?(logstash_local_connection_file_path) }
  end

  template "logstash-forwarder.conf" do
    path "/etc/logstash-forwarder.conf"
    source "logstash-forwarder.conf.erb"
    mode "0644"
    owner "root"
    group "root"

    variables(
        :mail_logs         => node['sophos_cloud_common']['configure_logstash_forwarder']['mail_logs'] == 'True',
        :nginx_logs        => node['sophos_cloud_common']['configure_logstash_forwarder']['nginx_logs'] == 'True',
        :custom_logs       => node['sophos_cloud_common']['configure_logstash_forwarder']['custom_logs'] == 'True',
        :sophos_logs       => node['sophos_cloud_common']['configure_logstash_forwarder']['sophos_logs'] == 'True',
        :logstash_server   => logstash_server_address,
        :logstash_timeout  => node['sophos_cloud_common']['configure_logstash_forwarder']['logstash_timeout'],
        :instance_log_path => node['sophos_cloud_common']['configure_logstash_forwarder']['instance_log_path'].split(',').collect{|x| '"' + x + '"'}.join(','),
        :instance_log_type => node['sophos_cloud_common']['configure_logstash_forwarder']['instance_log_type'],
        :sophos_log_path   => node['sophos_cloud_common']['configure_logstash_forwarder']['sophos_log_path'].split(',').collect{|x| '"' + x + '/sophos.log"'}.join(','),
        :sophos_log_type   => node['sophos_cloud_common']['configure_logstash_forwarder']['sophos_log_type'],
        :wildfly_logs      => node['sophos_cloud_common']['configure_logstash_forwarder']['wildfly_logs'] == 'True',
        :wildfly_log_path  => node['sophos_cloud_common']['configure_logstash_forwarder']['wildfly_log_path'].split(',').collect{|x| '"' + x + '"'}.join(','),
        :wildfly_log_type  => node['sophos_cloud_common']['configure_logstash_forwarder']['wildfly_log_type'],
        :region            => node['sophos_cloud']['region'],
        :branch            => node['sophos_cloud']['branch'],
        :env               => node['sophos_cloud']['environment'],
        :app               => node['sophos_cloud']['application_name'],
        :instance_id       => node['sophos_cloud']['instance_id']
    )
    only_if { ::File.exists?("#{node['sophos_cloud']['local_key_path']}/#{logstash_local_key_filename}.key") }

    notifies :restart, "service[logstash-forwarder]"
  end

  service "logstash-forwarder" do
    action :start
    only_if { ::File.exists?("#{node['sophos_cloud']['local_key_path']}/#{logstash_local_key_filename}.key") }
  end

  #Send ping message
  cron 'ping_syslog' do
    minute '*/5'
    command "/bin/bash -c 'logger \"[PING] this is a heartbeat message [$RANDOM]\"'"
  end


end
