#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: deploy_certs -- this runs during AMI deployment
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

tomcat_path = "/usr/share/tomcat"

default_java_path = "`(readlink -f /usr/lib/jvm/default-java | sed \"s:bin/java::\")`"
keytool = "#{default_java_path}/bin/keytool"

SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD = node['tomcat']['should_update_keystore'] ? 'true' : 'false'

execute "tomcat stop" do
  command node['tomcat']['stop_command']
  ignore_failure true
end

tmp_certificate_download_path = "#{node['sophos_cloud']['tmp']}/certificates"
java_cert_file_path = "#{default_java_path}/jre/lib/security/cacerts"
truststore_pass = "changeit"
keystore_pass = SecureRandom.hex(12)

MX_CERT_NAME = node['cert']['mx']

SHOULD_INSTALL_MX = node['cert']['should_install_mx']

ruby_block "Randomly generate keystore password" do
  block do
    node.default['tomcat']['keystore_pass'] = keystore_pass
  end
end

cookbook_file "tomcat.jks" do
  path "#{node['tomcat']['sophos_dir']}/tomcat.jks"
  action :delete
end

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

# Configure server.xml and context.xml
directory "/data/var/conf" do
  mode "0755"
  owner "tomcat"
  group "tomcat"
  recursive true
end

template "server.xml" do
  path "/data/var/conf/server.xml"
  if node['sophos_cloud']['cluster'] == "dep"
    source "tomcat8-server-client-ssl.xml.erb"
  else
    source "tomcat8-server-ssl.xml.erb"
  end
  mode "0644"
  owner "tomcat"
  group "tomcat"
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

# Retrieve and install smtp client key and certificate...

include_recipe "sophos-cloud-tomcat::deploy_email_cert"

# Add MongoDB connection cert to Tomcat truststore

bash "add_mongodb_to_keystore" do
user "root"
cwd "/tmp"
code <<-EOH
  mv /tmp/sophos/certificates/mongodb*.crt /etc/ssl/certs/mongodb.crt

  chmod 0444 /etc/ssl/certs/mongodb.crt
  chown root:root /etc/ssl/certs/mongodb.crt

  if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
  then
    openssl x509 -outform der -in /etc/ssl/certs/mongodb.crt -out /data/etc/mongodb.der
    #{keytool} -import -trustcacerts -file /data/etc/mongodb.der -alias sophos:mongodb -destkeystore #{java_cert_file_path} -deststorepass #{truststore_pass} -noprompt
    rm /data/etc/mongodb.der
  fi
EOH
end

# Add IAPI connection cert to Tomcat truststore
bash "add_iapi_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/service_ca-zero-iapi.crt /etc/ssl/certs/hmr-iapi.crt

  chmod 0444 /etc/ssl/certs/hmr-iapi.crt
  chown root:root /etc/ssl/certs/hmr-iapi.crt

  if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
  then
    openssl x509 -outform der -in /etc/ssl/certs/hmr-iapi.crt -out /data/etc/hmr-iapi.der
    #{keytool} -import -trustcacerts -file /data/etc/hmr-iapi.der -alias sophos:iapi -destkeystore #{java_cert_file_path} -deststorepass #{truststore_pass} -noprompt
    rm /data/etc/hmr-iapi.der
  fi
  EOH
end

# Add HUB connection cert to Tomcat truststore
bash "add_hub_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/hub-services*.crt /etc/ssl/certs/hub-services.crt

  chmod 0444 /etc/ssl/certs/hub-services.crt
  chown root:root /etc/ssl/certs/hub-services.crt

  if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
  then
    openssl x509 -outform der -in /etc/ssl/certs/hub-services.crt -out /data/etc/hub-services.der
    #{keytool} -import -trustcacerts -file /data/etc/hub-services.der -alias sophos:hub -destkeystore #{java_cert_file_path} -deststorepass #{truststore_pass} -noprompt
    rm /data/etc/hub-services.der
  fi
  EOH
end

# Add hmr-bsintegration cert to Tomcat truststore
bash "add_hmr-bsintegration_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/hmr-bsintegration*.crt /etc/ssl/certs/hmr-bsintegration-ca.crt

  chmod 0444 /etc/ssl/certs/hmr-bsintegration-ca.crt
  chown root:root /etc/ssl/certs/hmr-bsintegration-ca.crt

  if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
  then
    openssl x509 -outform der -in /etc/ssl/certs/hmr-bsintegration-ca.crt -out /data/etc/hmr-bsintegration-ca.der
    #{keytool} -import -trustcacerts -file /data/etc/hmr-bsintegration-ca.der -alias sophos:bsintegration -destkeystore #{java_cert_file_path} -deststorepass #{truststore_pass} -noprompt

    rm /data/etc/hmr-bsintegration-ca.der
  fi
  EOH
end

# Add hmr-infrastructure cert to Tomcat truststore
bash "add_hmr-infrastructure_to_keystore" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  mv /tmp/sophos/certificates/hmr-infrastructure*.crt /etc/ssl/certs/hmr-infrastructure-ca.crt

  chmod 0444 /etc/ssl/certs/hmr-infrastructure-ca.crt
  chown root:root /etc/ssl/certs/hmr-infrastructure-ca.crt

  if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
  then
    openssl x509 -outform der -in /etc/ssl/certs/hmr-infrastructure-ca.crt -out /data/etc/hmr-infrastructure-ca.der
    #{keytool} -import -trustcacerts -file /data/etc/hmr-infrastructure-ca.der -alias sophos:hmr-infrastructure -destkeystore #{java_cert_file_path} -deststorepass #{truststore_pass} -noprompt

    rm /data/etc/hmr-infrastructure-ca.der
  fi
  EOH
end

#TODO with this code we can stop using the default JAVA keystore and actually specify CAs we want to trust
# Add 3rd party certificate authorities to Tomcat truststore
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

  if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
  then
    if find ${THIRDPARTY_DIR} -type f -name '*.crt' 1> /dev/null 2>&1; then
      find ${THIRDPARTY_DIR} -type f -name '*.crt' | xargs -I{} #{keytool} -importcert -file {} -keystore #{java_cert_file_path} -alias "3rdparty:{}" -storepass #{truststore_pass} -noprompt
    fi
  fi

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

  ls -d /etc/ssl/certs/dep-services/*.crt | xargs -I{} #{keytool} -importcert -file {} -keystore #{java_cert_file_path} -alias "sophos:{}" -storepass #{truststore_pass} -noprompt

  rm -rf /etc/ssl/certs/dep-services/
  EOH
end

bash "add_infrastructure_rootca_to_bundle" do
  user "root"
  cwd "#{tmp_certificate_download_path}"
  code <<-EOH
    cat ./hmr-infrastructure.crt >> #{node['sophos_cloud']['local_cert_path']}/ca-bundle.crt
  EOH
  only_if { ::File.exists?("#{tmp_certificate_download_path}/hmr-infrastructure.crt") }
end

# Add ssl.properties for client cert auth
template "ssl.properties" do
  path "#{node['tomcat']['sophos_dir']}/ssl.properties"
  source "ssl.properties.erb"
  mode "0640"
  owner "tomcat"
  group "tomcat"
  variables(
      :jks_location => "#{node['tomcat']['sophos_dir']}/tomcat.jks",
      :client_cert_store => "#{node['tomcat']['client_cert_store']}",
      :jks_password => keystore_pass
  )
end

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

        if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
        then
          openssl pkcs12 -export -in /etc/ssl/certs/#{node['cert']['default']}.crt -inkey /etc/ssl/private/#{node['cert']['default']}.key -out /data/etc/#{node['cert']['default']}.p12 -passout "pass:#{keystore_pass}"
          #{keytool} -importkeystore -srckeystore /data/etc/#{node['cert']['default']}.p12 -srcstoretype PKCS12 -srcstorepass #{keystore_pass} -destkeystore #{node['tomcat']['sophos_dir']}/tomcat.jks -deststoretype JKS -deststorepass #{keystore_pass}
          chmod 0600 #{node['tomcat']['sophos_dir']}/tomcat.jks
          chown tomcat:tomcat #{node['tomcat']['sophos_dir']}/tomcat.jks

          rm /data/etc/#{node['cert']['default']}.p12
        fi
  EOH
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

# Add application specific certs to Tomcat keystore
case node['sophos_cloud']['cluster']
  when "api"
    bash "add_api_to_keystore" do
      user "root"
      cwd "/tmp"
      code <<-EOH
        mv /tmp/sophos/certificates/appserver*.crt /etc/ssl/certs/#{node['cert']['api']}.crt
        chmod 0444 /etc/ssl/certs/#{node['cert']['api']}.crt
        chown root:root /etc/ssl/certs/#{node['cert']['api']}.crt

        mv /tmp/sophos/certificates/appserver*.key /etc/ssl/private/#{node['cert']['api']}.key
        chmod 0440 /etc/ssl/private/#{node['cert']['api']}.key
        chown root:root /etc/ssl/private/#{node['cert']['api']}.key

        # Create SHA256 hash of the cert
        openssl x509 -in /etc/ssl/certs/#{node['cert']['api']}.crt -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64 >/etc/ssl/certs/#{node['cert']['api']}.sha256

        if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
        then
          openssl pkcs12 -export -in /etc/ssl/certs/#{node['cert']['api']}.crt -inkey /etc/ssl/private/#{node['cert']['api']}.key -out /data/etc/#{node['cert']['api']}.p12 -passout "pass:#{keystore_pass}"
          #{keytool} -importkeystore -srckeystore /data/etc/#{node['cert']['api']}.p12 -srcstoretype PKCS12 -srcalias 1 -srcstorepass #{keystore_pass} -destkeystore #{node['tomcat']['sophos_dir']}/tomcat.jks -deststoretype JKS -destalias #{node['cert']['api']} -deststorepass #{keystore_pass}
          chmod 0600 #{node['tomcat']['sophos_dir']}/tomcat.jks
          chown tomcat:tomcat #{node['tomcat']['sophos_dir']}/tomcat.jks

          rm /data/etc/#{node['cert']['api']}.p12
        fi
      EOH
    end

  when "core"
    # Add Zero IAPI keys and Business Systems Integration CA to Java svc_core keystore
    bash "add_core_to_keystore" do
      user "root"
      cwd "/tmp"
      code <<-EOH
        mv /tmp/sophos/certificates/iapi*.crt /etc/ssl/certs/#{node['cert']['core']}.crt
        chmod 0444 /etc/ssl/certs/#{node['cert']['core']}.crt
        chown root:root /etc/ssl/certs/#{node['cert']['core']}.crt

        mv /tmp/sophos/certificates/iapi*.key /etc/ssl/private/#{node['cert']['core']}.key
        chmod 0440 /etc/ssl/private/#{node['cert']['core']}.key
        chown root:ssl-cert /etc/ssl/private/#{node['cert']['core']}.key

        if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
        then
          openssl pkcs12 -export -in /etc/ssl/certs/#{node['cert']['core']}.crt -inkey /etc/ssl/private/#{node['cert']['core']}.key -out /data/etc/#{node['cert']['core']}.p12 -passout "pass:#{keystore_pass}"
          #{keytool} -importkeystore -srckeystore /data/etc/#{node['cert']['core']}.p12 -srcstoretype PKCS12 -srcalias 1 -srcstorepass #{keystore_pass} -destkeystore #{node['tomcat']['sophos_dir']}/tomcat.jks -deststoretype JKS -destalias #{node['cert']['core']} -deststorepass #{keystore_pass}
          chmod 0600 #{node['tomcat']['sophos_dir']}/tomcat.jks
          chown tomcat:tomcat #{node['tomcat']['sophos_dir']}/tomcat.jks
          rm /data/etc/#{node['cert']['core']}.p12
        fi
      EOH
    end

  when "dep"
    # Add
    bash "add_dep_to_keystore" do
      user "root"
      cwd "/tmp"
      code <<-EOH
        mv /tmp/sophos/certificates/dep-services/dep*.crt /etc/ssl/certs/#{node['cert']['dep']}.crt
        chmod 0444 /etc/ssl/certs/#{node['cert']['dep']}.crt
        chown root:root /etc/ssl/certs/#{node['cert']['dep']}.crt

        mv /tmp/sophos/certificates/dep-services/dep*.key /etc/ssl/private/#{node['cert']['dep']}.key
        chmod 0440 /etc/ssl/private/#{node['cert']['dep']}.key
        chown root:root /etc/ssl/private/#{node['cert']['dep']}.key

        if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
        then
          openssl pkcs12 -export -in /etc/ssl/certs/#{node['cert']['dep']}.crt -inkey /etc/ssl/private/#{node['cert']['dep']}.key -out /data/etc/#{node['cert']['dep']}.p12 -passout "pass:#{keystore_pass}"
          #{keytool} -importkeystore -srckeystore /data/etc/#{node['cert']['dep']}.p12 -srcstoretype PKCS12 -srcalias 1 -srcstorepass #{keystore_pass} -destkeystore #{node['tomcat']['sophos_dir']}/tomcat.jks -deststoretype JKS -destalias #{node['cert']['dep']} -deststorepass #{keystore_pass}
          chmod 640 #{node['tomcat']['sophos_dir']}/tomcat.jks
          chown root:tomcat #{node['tomcat']['sophos_dir']}/tomcat.jks
          rm /data/etc/#{node['cert']['dep']}.p12

          # Create certs dir on encrypted store
          mkdir -p /data/dep_clients

          # Import Salesforce/DEP integration certificates
          mv /tmp/sophos/certificates/dep-services/integration /data/dep_clients/integration
          chmod 0444 /data/dep_clients/integration
          chown root:tomcat /data/dep_clients/integration
          ls -d /data/dep_clients/integration/* | xargs -I{} #{keytool} -noprompt -importcert -file {} -keystore /usr/local/etc/sophos/integration.jks -alias "{}" -storepass "#{keystore_pass}"

          # Import IAPI certificates
          mv /tmp/sophos/certificates/dep-services/iapi /data/dep_clients/iapi
          chmod 0444 /data/dep_clients/iapi
          chown root:tomcat /data/dep_clients/iapi
          ls -d /data/dep_clients/iapi/* | xargs -I{} #{keytool} -noprompt -importcert -file {} -keystore /usr/local/etc/sophos/iapi.jks -alias "{}" -storepass "#{keystore_pass}"

          # Import Service Registration API certificates
          mv /tmp/sophos/certificates/dep-services/registration /data/dep_clients/registration
          chmod 0444 /data/dep_clients/registration
          chown root:tomcat /data/dep_clients/registration
          ls -d /data/dep_clients/registration/* | xargs -I{} #{keytool} -noprompt -importcert -file {} -keystore /usr/local/etc/sophos/registration.jks -alias "{}" -storepass "#{keystore_pass}"

          # Import Support Portal certificates
          mv /tmp/sophos/certificates/dep-services/support /data/dep_clients/support
          chmod 0444 /data/dep_clients/support
          chown root:tomcat /data/dep_clients/support
          ls -d /data/dep_clients/support/* | xargs -I{} #{keytool} -noprompt -importcert -file {} -keystore /usr/local/etc/sophos/support.jks -alias "{}" -storepass "#{keystore_pass}"

          # Clean up certificates
          rm -rf /data/dep_clients
        fi
      EOH
    end

  when "hub"
    bash "add_hub_to_keystore" do
      user "root"
      cwd "/tmp"
      code <<-EOH
        set -e

        aws configure set default.s3.signature_version s3v4

        #{node['sophos_cloud']['script_path']}/download-object #{node['sophos_cloud']['context']} \
                                                               #{node['sophos_cloud']['connections']} \
                                                               #{node['saml']['keystore_password']} \
                                                               "#{node['sophos_cloud']['tmp']}/#{node['saml']['keystore_password']}" || true

        mv /tmp/sophos/certificates/hub-services/hub-services*.crt /etc/ssl/certs/#{node['cert']['hub']}.crt
        chmod 0444 /etc/ssl/certs/#{node['cert']['hub']}.crt
        chown root:root /etc/ssl/certs/#{node['cert']['hub']}.crt

        mv /tmp/sophos/certificates/hub-services/hub-services*.key /etc/ssl/private/#{node['cert']['hub']}.key
        chmod 0440 /etc/ssl/private/#{node['cert']['hub']}.key
        chown root:root /etc/ssl/private/#{node['cert']['hub']}.key

        # Create SHA256 hash of the cert
        openssl x509 -in /etc/ssl/certs/#{node['cert']['hub']}.crt -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64 >/etc/ssl/certs/#{node['cert']['hub']}.sha256

        if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
        then
          openssl pkcs12 -export -in /etc/ssl/certs/#{node['cert']['hub']}.crt -inkey /etc/ssl/private/#{node['cert']['hub']}.key -out /data/etc/#{node['cert']['hub']}.p12 -passout "pass:#{keystore_pass}"
          #{keytool} -importkeystore -srckeystore /data/etc/#{node['cert']['hub']}.p12 -srcstoretype PKCS12 -srcalias 1 -srcstorepass #{keystore_pass} -destkeystore #{node['tomcat']['sophos_dir']}/tomcat.jks -deststoretype JKS -destalias #{node['cert']['hub']} -deststorepass #{keystore_pass}
          chmod 640 #{node['tomcat']['sophos_dir']}/tomcat.jks
          chown root:tomcat #{node['tomcat']['sophos_dir']}/tomcat.jks
          rm /data/etc/#{node['cert']['hub']}.p12

          # Import Client Certificate PEMs into a directory on the encrypted partition with a shared keystore
          mkdir -p /data/clientCertStore
          mv /tmp/sophos/certificates/hub-services/client-cert-pems/ /data/client-cert-pems
          chmod -R 0444 /data/client-cert-pems
          chown root:tomcat /data/client-cert-pems
          ls /data/client-cert-pems/*.pem | xargs basename | sed 's/.pem$//' | xargs -I{} openssl pkcs12 -export -in /data/client-cert-pems/{}.pem -out /data/clientCertStore/{}.p12 -passout "pass:#{keystore_pass}"
          rm -rf /data/client-cert-pems

          # Setup SAML (Okta) keystore
          mkdir -p /data/okta
          mv /tmp/sophos/certificates/hub-services/saml.crt /data/okta/saml.crt
          chmod 0444 /data/okta/saml.crt
          chown root:root /data/okta/saml.crt

          mv /tmp/sophos/certificates/hub-services/saml.key /data/okta/saml.key
          chmod 0440 /data/okta/saml.key
          chown root:root /data/okta/saml.key

          SAML_KEYSTORE_PASSWORD=$(cat #{node['sophos_cloud']['tmp']}/#{node['saml']['keystore_password']})

          openssl pkcs12 -export -in /data/okta/saml.crt -inkey /data/okta/saml.key -out /data/okta/saml.p12 -passout "pass:$SAML_KEYSTORE_PASSWORD" -name "#{node['saml']['keystore_alias']}"
          #{keytool} -importkeystore -srckeystore /data/okta/saml.p12 -srcstoretype PKCS12 -srcstorepass "$SAML_KEYSTORE_PASSWORD" -destkeystore #{node['saml']['keystore_location']} -deststoretype JKS -deststorepass "$SAML_KEYSTORE_PASSWORD"

          if [ -f /tmp/sophos/certificates/hub-services/okta.crt ]; then cp /tmp/sophos/certificates/hub-services/okta.crt /data/okta/okta.crt; fi
          if [ -f /data/okta/okta.crt ]; then #{keytool} -noprompt -importcert -file /data/okta/okta.crt -keystore #{node['saml']['keystore_location']} -alias "okta" -storepass $SAML_KEYSTORE_PASSWORD; fi
          rm -rf /data/okta
          chmod 0600 #{node['saml']['keystore_location']} || true
          chown tomcat:tomcat #{node['saml']['keystore_location']} || true
        fi
      EOH
    end

  when "mcs"
    bash "add_mcs_to_keystore" do
      user "root"
      cwd "/tmp"
      code <<-EOH
        mv /tmp/sophos/certificates/mcsbroker*.crt /etc/ssl/certs/#{node['cert']['mcs']}.crt
        chmod 0444 /etc/ssl/certs/#{node['cert']['mcs']}.crt
        chown root:root /etc/ssl/certs/#{node['cert']['mcs']}.crt

        mv /tmp/sophos/certificates/mcsbroker*.key /etc/ssl/private/#{node['cert']['mcs']}.key
        chmod 0440 /etc/ssl/private/#{node['cert']['mcs']}.key
        chown root:root /etc/ssl/private/#{node['cert']['mcs']}.key

        if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
        then
          openssl pkcs12 -export -in /etc/ssl/certs/#{node['cert']['mcs']}.crt -inkey /etc/ssl/private/#{node['cert']['mcs']}.key -out /data/etc/#{node['cert']['mcs']}.p12 -passout "pass:#{keystore_pass}"
          #{keytool} -importkeystore -srckeystore /data/etc/#{node['cert']['mcs']}.p12 -srcstoretype PKCS12 -srcalias 1 -srcstorepass #{keystore_pass} -destkeystore #{node['tomcat']['sophos_dir']}/tomcat.jks -deststoretype JKS -destalias #{node['cert']['mcs']} -deststorepass #{keystore_pass}
          chmod 0600 #{node['tomcat']['sophos_dir']}/tomcat.jks
          chown tomcat:tomcat #{node['tomcat']['sophos_dir']}/tomcat.jks

          rm /data/etc/#{node['cert']['mcs']}.p12
        fi
      EOH
    end

  when "mob"
    bash "add_mob_to_keystore" do
      user "root"
      cwd "/tmp"
      code <<-EOH
        mv /tmp/sophos/certificates/mobile-frontend*.crt /etc/ssl/certs/#{node['cert']['mob']}.crt
        chmod 0444 /etc/ssl/certs/#{node['cert']['mob']}.crt
        chown root:root /etc/ssl/certs/#{node['cert']['mob']}.crt

        mv /tmp/sophos/certificates/mobile-frontend*.key /etc/ssl/private/#{node['cert']['mob']}.key
        chmod 0440 /etc/ssl/private/#{node['cert']['mob']}.key
        chown root:root /etc/ssl/private/#{node['cert']['mob']}.key

        if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
        then
          openssl pkcs12 -export -in /etc/ssl/certs/#{node['cert']['mob']}.crt -inkey /etc/ssl/private/#{node['cert']['mob']}.key -out /data/etc/#{node['cert']['mob']}.p12 -passout "pass:#{keystore_pass}"
          #{keytool} -importkeystore -srckeystore /data/etc/#{node['cert']['mob']}.p12 -srcstoretype PKCS12 -srcalias 1 -srcstorepass #{keystore_pass} -destkeystore #{node['tomcat']['sophos_dir']}/tomcat.jks -deststoretype JKS -destalias #{node['cert']['mob']} -deststorepass #{keystore_pass}
          chmod 0600 #{node['tomcat']['sophos_dir']}/tomcat.jks
          chown tomcat:tomcat #{node['tomcat']['sophos_dir']}/tomcat.jks

          rm /data/etc/#{node['cert']['mob']}.p12
        fi
      EOH
    end

  when "utm"
    bash "add_utm_to_keystore" do
      user "root"
      cwd "/tmp"
      code <<-EOH
        mv /tmp/sophos/certificates/utm*.crt /etc/ssl/certs/#{node['cert']['utm']}.crt
        chmod 0444 /etc/ssl/certs/#{node['cert']['utm']}.crt
        chown root:root /etc/ssl/certs/#{node['cert']['utm']}.crt

        mv /tmp/sophos/certificates/utm*.key /etc/ssl/private/#{node['cert']['utm']}.key
        chmod 0440 /etc/ssl/private/#{node['cert']['utm']}.key
        chown root:root /etc/ssl/private/#{node['cert']['utm']}.key

        if '#{SHOULD_UPDATE_TOMCAT_KEYSTORE_CHECK_CMD}'
        then
          openssl pkcs12 -export -in /etc/ssl/certs/#{node['cert']['utm']}.crt -inkey /etc/ssl/private/#{node['cert']['utm']}.key -out /data/etc/#{node['cert']['utm']}.p12 -passout "pass:#{keystore_pass}"
          #{keytool} -importkeystore -srckeystore /data/etc/#{node['cert']['utm']}.p12 -srcstoretype PKCS12 -srcalias 1 -srcstorepass #{keystore_pass} -destkeystore #{node['tomcat']['sophos_dir']}/tomcat.jks -deststoretype JKS -destalias #{node['cert']['utm']} -deststorepass #{keystore_pass}
          chmod 0600 #{node['tomcat']['sophos_dir']}/tomcat.jks
          chown tomcat:tomcat #{node['tomcat']['sophos_dir']}/tomcat.jks

          rm /data/etc/#{node['cert']['utm']}.p12
        fi
      EOH
    end
end

# Add smc specific keystore secret to tomcat instance
if node['sophos_cloud']['cluster'] == 'smc'
  include_recipe "sophos-cloud-smc::keystores"
end

execute "delete temp files from tomcat/lib" do
  command "rm -f #{tomcat_path}/lib/._*.jar"
end
