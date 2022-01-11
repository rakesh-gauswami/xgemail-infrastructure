#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: deploy_certs -- this runs during instance deployment
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#

ACCOUNT_NAME = node['sophos_cloud']['account_name']

tmp_certificate_download_path = "#{node['sophos_cloud']['tmp']}/certificates"

MX_CERT_NAME = node['cert']['mx']

SHOULD_INSTALL_MX = node['cert']['should_install_mx']

directory "/tmp/sophos" do
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

directory "/tmp/sophos/certificates" do
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

directory "/etc/ssl/private" do
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

bash "download_hammer_connections" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  aws configure set default.s3.signature_version s3v4

  aws --region us-west-2 s3 cp s3://#{node['sophos_cloud']['connections']}/hammer-connections.tar.gz #{node['sophos_cloud']['tmp']}
  tar -xzvf #{node['sophos_cloud']['tmp']}/hammer-connections.tar.gz -C #{tmp_certificate_download_path}
  EOH
end

file "#{node['sophos_cloud']['tmp']}/hammer-connections.tar.gz" do
  action :delete
end

# Add MongoDB connection cert to Certificate truststore

bash "add_mongodb_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/mongodb*.crt /etc/ssl/certs/mongodb.crt
  
  chmod 0444 /etc/ssl/certs/mongodb.crt
  chown root:root /etc/ssl/certs/mongodb.crt

  EOH
end

# Add IAPI connection cert to Certificate truststore
bash "add_iapi_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/service_ca-zero-iapi.crt /etc/ssl/certs/hmr-iapi.crt

  chmod 0444 /etc/ssl/certs/hmr-iapi.crt
  chown root:root /etc/ssl/certs/hmr-iapi.crt

  EOH
end

# Add HUB connection cert to Certificate truststore
bash "add_hub_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/hub-services*.crt /etc/ssl/certs/hub-services.crt

  chmod 0444 /etc/ssl/certs/hub-services.crt
  chown root:root /etc/ssl/certs/hub-services.crt

  EOH
end

# Add hmr-bsintegration cert to Certificate truststore
bash "add_hmr-bsintegration_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/hmr-bsintegration*.crt /etc/ssl/certs/hmr-bsintegration-ca.crt

  chmod 0444 /etc/ssl/certs/hmr-bsintegration-ca.crt
  chown root:root /etc/ssl/certs/hmr-bsintegration-ca.crt

  EOH
end

# Add hmr-infrastructure cert to Certificate truststore
bash "add_hmr-infrastructure_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/hmr-infrastructure*.crt /etc/ssl/certs/hmr-infrastructure-ca.crt

  chmod 0444 /etc/ssl/certs/hmr-infrastructure-ca.crt
  chown root:root /etc/ssl/certs/hmr-infrastructure-ca.crt

  cp /etc/ssl/certs/hmr-infrastructure-ca.crt /etc/pki/ca-trust/source/anchors/
  /usr/bin/update-ca-trust extract

  EOH
end

#TODO with this code we can stop using the default JAVA keystore and actually specify CAs we want to trust
# Add 3rd party certificate authorities to Certificate truststore
# There is a 'global-sign' directory inside 3rdparty that contains GlobalSign's root
# and intermediary signing certificates.
bash "add_3rdparty_certificate_authorities_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  set -eux
  THIRDPARTY_DIR=/etc/ssl/certs/3rdparty
  install -d -m 755 -o root -g root "${THIRDPARTY_DIR}"
  rsync -av /tmp/sophos/certificates/3rdparty/ "${THIRDPARTY_DIR}/"

  chmod -cR u=rX,g=rX,o=rX "${THIRDPARTY_DIR}"
  chown -cR root:root "${THIRDPARTY_DIR}"
  find "${THIRDPARTY_DIR}" -type d -exec chmod -c u+w {} \\;

  EOH
end

# Add dep-services certificates to Tomcat truststore
bash "add_dep_services_certificates_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mkdir -p /etc/ssl/certs/dep-services/
  mv /tmp/sophos/certificates/dummy-lp*.crt /etc/ssl/certs/dep-services/dummy-lp.crt
  mv /tmp/sophos/certificates/hmr-pubservices*.crt /etc/ssl/certs/dep-services/hmr-pubservices.crt
  mv /tmp/sophos/certificates/internal-it*.crt /etc/ssl/certs/dep-services/internal-it.crt
  mv /tmp/sophos/certificates/sophos-home*.crt /etc/ssl/certs/dep-services/sophos-home.crt

  chmod 0444 /etc/ssl/certs/dep-services/*.crt
  chown root:root /etc/ssl/certs/dep-services/*.crt

  rm -rf /etc/ssl/certs/dep-services/
  EOH
end

if ACCOUNT_NAME == 'legacy'
  bash "add_default_cert_to_keystore" do
    user "root"
    cwd "/tmp"
    code <<-EOH
          mv /tmp/sophos/certificates/*hydra.sophos.com.crt /etc/ssl/certs/#{node['cert']['default']}.crt
          chmod 0444 /etc/ssl/certs/#{node['cert']['default']}.crt
          chown root:root /etc/ssl/certs/#{node['cert']['default']}.crt
  
          mv /tmp/sophos/certificates/*hydra.sophos.com.key /etc/ssl/private/#{node['cert']['default']}.key
          chmod 0440 /etc/ssl/private/#{node['cert']['default']}.key
          chown root:root /etc/ssl/private/#{node['cert']['default']}.key

    EOH
  end
else
  bash "add_default_cert_to_keystore" do
    user "root"
    cwd "/tmp"
    code <<-EOH
          mv /tmp/sophos/certificates/*ctr.sophos.com.crt /etc/ssl/certs/#{node['cert']['default']}.crt
          chmod 0444 /etc/ssl/certs/#{node['cert']['default']}.crt
          chown root:root /etc/ssl/certs/#{node['cert']['default']}.crt
  
          mv /tmp/sophos/certificates/*ctr.sophos.com.key /etc/ssl/private/#{node['cert']['default']}.key
          chmod 0440 /etc/ssl/private/#{node['cert']['default']}.key
          chown root:root /etc/ssl/private/#{node['cert']['default']}.key

    EOH
  end
end

# Add mx certificate
remote_file "/etc/ssl/certs/#{MX_CERT_NAME}.crt" do
  source "file:///tmp/sophos/certificates/mx/mx.crt"
  owner 'root'
  group 'root'
  mode 0444
  only_if { SHOULD_INSTALL_MX }
end

# Add mx key
remote_file "/etc/ssl/private/#{MX_CERT_NAME}.key" do
  source "file:///tmp/sophos/certificates/mx/mx.key"
  owner 'root'
  group 'root'
  mode 0440
  only_if { SHOULD_INSTALL_MX }
end
