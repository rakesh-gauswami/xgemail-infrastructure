#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: install_event_svc_auth -- this runs during AMI deployment, sets up the basic auth credential file to talk to
# the event service
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

is_station = node['sophos_cloud']['cluster'] != 'hub' && node['sophos_cloud']['cluster'] != 'dep'
is_java_app = node['sophos_cloud']['is_java_app'] == "yes"
event_svc_auth_dir = node['tomcat']['sophos_dir'] + "/event_svc"

directory event_svc_auth_dir do
  mode "0700"
  owner "tomcat"
  group "tomcat"
  action :create
end

template '/usr/local/etc/sophos/event_svc/authentication.properties' do
  source 'dummy_event_svc_auth.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0644'
end

bash "download_event service auth" do
  user "root"
  cwd "/tmp"
  code <<-EOH
          mkdir -p /tmp/sophos/event_svc_auth
          BUCKET=#{node['sophos_cloud']['event_svc_auth_bucket']}
          PROPERTIES_FILE=authentication.properties

          aws configure set default.s3.signature_version s3v4
          aws --region us-west-2 s3 cp s3://${BUCKET}/event/${PROPERTIES_FILE} /tmp/sophos/event_svc_auth/${PROPERTIES_FILE}
          mv /tmp/sophos/event_svc_auth/${PROPERTIES_FILE} #{event_svc_auth_dir}/
          chown -R tomcat:tomcat #{event_svc_auth_dir}/
  EOH
  ignore_failure true
  only_if { is_station && is_java_app }
end
