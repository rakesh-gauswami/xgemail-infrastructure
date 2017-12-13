#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: deploy -- this runs during AMI image creation
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Install property files

template "application.properties" do
  path "#{node['tomcat']['sophos_dir']}/application.properties"
  source "application.properties.erb"
  mode "0640"
  owner "tomcat"
  group "tomcat"
  variables(
      :mongodb_addresses => '192.0.0.0:27017',
      :mongodb_username => 'admin',
      :mongodb_password => 'some password',
      :redis_addresses => '192.0.0.0:6379',
      :keystore_addresses => 'alliance.dummyurl'
  )
end

template "bootstrap.properties" do
  path "#{node['tomcat']['sophos_dir']}/bootstrap.properties"
  source "bootstrap.properties.erb"
  mode "0640"
  owner "tomcat"
  group "tomcat"
  variables(
      :elasticsearch_addresses => '192.0.0.0:9200',
      :redis_addresses => '192.0.0.0:6379',
      :redis_auth => 'auth auth auth',
      :redis_database => 'database',
      :mongodb_addresses => '192.0.0.0:27017',
      :mongodb_username => 'admin',
      :mongodb_password => 'some password',
      :mongodb_database => 'sledge',
      :mongodb_ep_database => 'ep',
      :zero_url => 'zero.url',
      :zero_id => 'zero.id',
      :zero_token => 'zero.token',
      :upe_id => 'upe.id',
      :upe_token => 'upe.token'
  )
end

# Download the application
bash "download_war" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['application']}/ /tmp/ --recursive

    # Rename encrypted mobile WAR
    mv mob*-services.enc mob-services.enc

    # Copy encrypted hub WAR to dep WAR
    cp hub-services.enc dep-services.enc
  EOH
end

# Decrypt the application
bash "decrypt_war" do
  user "root"
  cwd "/tmp"
  code <<-EOH
      for war in *-services.enc; do
        war_name=${war%-services.enc}
        openssl enc -aes-256-cbc -d -in /tmp/$war -out /tmp/"$war_name".war -pass pass:#{node['sophos_cloud']['aeskey']}
      done
  EOH
end
