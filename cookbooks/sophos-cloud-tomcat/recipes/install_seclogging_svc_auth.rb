#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: install_seclogging_svc_auth -- this runs during AMI deployment, sets up the basic auth credential file to talk to
# the seclogging service
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

is_station = node['sophos_cloud']['cluster'] != 'hub' && node['sophos_cloud']['cluster'] != 'dep'
is_java_app = node['sophos_cloud']['is_java_app'] == "yes"
seclogging_svc_auth_dir = node['tomcat']['sophos_dir'] + "/seclogging_svc"

directory seclogging_svc_auth_dir do
  mode "0770"
  owner "tomcat"
  group "tomcat"
  action :create
end

template '/usr/local/etc/sophos/seclogging_svc/authentication.properties' do
  source 'dummy_seclogging_svc_auth.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0664'
end

bash "download_seclogging service auth" do
  user "root"
  cwd "/tmp"
  code <<-EOH
          mkdir -p /tmp/sophos/seclogging_svc_auth
          BUCKET=#{node['sophos_cloud']['seclogging_svc_auth_bucket']}
          PROPERTIES_FILE=authentication.properties

          aws configure set default.s3.signature_version s3v4
          aws --region us-west-2 s3 cp s3://${BUCKET}/seclogging/${PROPERTIES_FILE} /tmp/sophos/seclogging_svc_auth/${PROPERTIES_FILE}
          mv /tmp/sophos/seclogging_svc_auth/${PROPERTIES_FILE} #{seclogging_svc_auth_dir}/
          chown -R tomcat:tomcat #{seclogging_svc_auth_dir}/
  EOH
  ignore_failure true
  only_if { is_station && is_java_app }
end
