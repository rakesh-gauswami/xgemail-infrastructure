#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: deploy_email_cert
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# default:=/tmp/sophos
tmp_certificate_download_path = "#{node['sophos_cloud']['tmp']}/certificates"

smtp_key_filename = "#{node['sophos_cloud']['context']}-connection-#{node['email']['key_filename']}"
smtp_connection_file = "#{smtp_key_filename}.tar.gz"
smtp_connection_path = "cloud-#{node['sophos_cloud']['context']}-connections/#{node['sophos_cloud']['client-endpoint']}/#{node['sophos_cloud']['vpc_name']}"

smtp_local_connection_file_path = "#{tmp_certificate_download_path}/#{smtp_connection_file}"
smtp_local_key_filename = "#{node['email']['key_filename']}"

file smtp_local_connection_file_path do
  action :delete
  only_if { node['email']['install'] == "yes" }
end

log "Download from S3: //#{smtp_connection_path}/#{smtp_connection_file} to #{tmp_certificate_download_path}" do
  level :info
  only_if { node['email']['install'] == "yes" }
end

bash "download_existing_smtp_keypair_and_cert" do
  user "root"
  cwd "#{tmp_certificate_download_path}"
  code <<-EOH
    aws configure set default.s3.signature_version s3v4
    aws --region us-west-2 s3 cp s3://#{smtp_connection_path}/#{smtp_connection_file}  #{tmp_certificate_download_path} || true
  EOH
  only_if { node['email']['install'] == "yes" }
end

log "Install SMTP cert: expand '#{smtp_local_connection_file_path}', copy '#{tmp_certificate_download_path}/#{smtp_key_filename}.crt'" do
  level :info
  only_if { node['email']['install'] == "yes" }
end

log "Install SMTP keys: expand '#{smtp_local_connection_file_path}', copy '#{tmp_certificate_download_path}/#{smtp_key_filename}.key'" do
  level :info
  only_if { node['email']['install'] == "yes" }
end

bash "install_smtp_client_keys" do
  user "root"
  cwd "#{tmp_certificate_download_path}"
  only_if { ::File.exists?(smtp_local_connection_file_path) }
  code <<-EOH
    tar -xzvf #{smtp_local_connection_file_path} --transform='s\/.*\\/\/\/'
  EOH
  only_if { node['email']['install'] == "yes" }
end

remote_file "#{node['sophos_cloud']['local_cert_path']}/#{smtp_local_key_filename}.crt" do
  source "file://#{tmp_certificate_download_path}/#{smtp_key_filename}.crt"
  owner 'root'
  group 'root'
  mode 0444
  only_if { node['email']['install'] == "yes" }
  only_if { ::File.exists?(smtp_local_connection_file_path) }
end

remote_file "#{node['sophos_cloud']['local_key_path']}/#{smtp_local_key_filename}.key" do
  source "file://#{tmp_certificate_download_path}/#{smtp_key_filename}.key"
  owner 'root'
  group 'root'
  mode 0440
  only_if { node['email']['install'] == "yes" }
  only_if { ::File.exists?(smtp_local_connection_file_path) }
end

file "#{tmp_certificate_download_path}/#{smtp_key_filename}.crt" do
  action :delete
  only_if { ::File.exists?(smtp_local_connection_file_path) }
end

file "#{tmp_certificate_download_path}/#{smtp_key_filename}.key" do
  action :delete
  only_if { ::File.exists?(smtp_local_connection_file_path) }
end

file smtp_local_connection_file_path do
  action :delete
  only_if { node['email']['install'] == "yes" }
end

log "Created smtp key file: #{node['sophos_cloud']['local_key_path']}/#{smtp_local_key_filename}.key" do
  level :info
  only_if { node['email']['install'] == "yes" }
end

log "Created smtp cert file: #{node['sophos_cloud']['local_cert_path']}/#{smtp_local_key_filename}.crt" do
  level :info
  only_if { node['email']['install'] == "yes" }
end
