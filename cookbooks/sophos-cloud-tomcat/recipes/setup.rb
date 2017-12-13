#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: setup -- this runs during AMI image creation
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Ruby characters in strings can be referenced by their index number.
# This node attribute, coming in as jdk-1.8*, is selecting the seventh index which is 8 in this example.
java_version = "#{node['sophos_cloud']['jdk_version']}"[6]

sophos_script_path = node['sophos_cloud']['script_path']
sophos_tmp_path = node['sophos_cloud']['tmp']

tomcat_path = "/usr/share/tomcat"

directory sophos_script_path do
  mode "0755"
  owner "root"
  group "root"
  action :create
  recursive true
end

directory sophos_tmp_path do
  mode "0755"
  owner "root"
  group "root"
  action :create
  recursive true
end

cookbook_file "download-object" do
  path "#{sophos_script_path}/download-object"
  source "download-object"
  mode "0755"
  owner "root"
  group "root"
end

cookbook_file "upload-object" do
  path "#{sophos_script_path}/upload-object"
  source "upload-object"
  mode "0755"
  owner "root"
  group "root"
end

# Add local IP to /etc/hosts
bash "edit_etc_hosts" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    echo "$(wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4) $(hostname)" >> /etc/hosts
  EOH
end

# Setting up iptables for privileged ports
bash "setup_iptables" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
  iptables -t nat -A PREROUTING -p tcp --dport 80  -j REDIRECT --to-port 8080
  iptables -t nat -A OUTPUT --dst 127.0.0.1 -p tcp --dport 443 -j REDIRECT --to-port 8443
  iptables -t nat -A OUTPUT --dst 127.0.0.1 -p tcp --dport 80  -j REDIRECT --to-port 8080
  EOH
end

# Install Oracle JDK
bash "Install Oracle JDK" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    set -e

    mkdir -p /usr/lib/tmp /usr/lib/jvm/
    aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['java']}/#{node['sophos_cloud']['jdk_version']}.tar.gz /usr/lib/tmp
    tar -xvf /usr/lib/tmp/#{node['sophos_cloud']['jdk_version']}.tar.gz -C /usr/lib/jvm/

    rm -rf /usr/lib/tmp

    # Items after keytool are not strictly required but may be helpful for debugging.
    for CMD in java javac keytool jar jcmd jdb jhat jinfo jmap jps jstack jstat; do
      update-alternatives --install "/usr/bin/${CMD}" "${CMD}" "/usr/lib/jvm/java-#{java_version}-oracle/bin/${CMD}" 20000
      chmod a+x "/usr/bin/${CMD}"
    done
  EOH
end

# Uninstall OpenJDK.
bash "remove_openjdk" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    for p in $(yum list installed | awk '/java/ {print $1}'); do
      yum remove -y $p
    done
  EOH
end

# Install Tomcat
bash "install_tomcat" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    mkdir -p /usr/lib/tmp
    aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['tomcat']} /usr/lib/tmp
    tar -xvf /usr/lib/tmp/tomcat*.tar.gz -C /usr/share/
    rm -rf /usr/lib/tmp
  EOH
end

template "/etc/rc.d/init.d/tomcat" do
  path "/etc/rc.d/init.d/tomcat"
  source "tomcat.erb"
  mode "0755"
  owner "root"
  group "root"
end

# Create tomcat user.
user "tomcat" do
  system true
  shell "/sbin/nologin"
end

# Create tomcat group.
group "tomcat" do
  members "tomcat"
  append true
end

# Create directories.
%w{log_dir pid_dir sophos_dir etc_dir tmp_dir webapp_dir}.each do |d|
  directory node["tomcat"][d] do
    owner "tomcat"
    group "tomcat"
    mode "0755"
    recursive true
  end
end

# Warning suppression for Tomcat startup
bash "suppress_tomcat_warnings" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    mkdir -p #{tomcat_path}/common/classes
    chown -R root:tomcat #{tomcat_path}/common
    chmod -R 771 #{tomcat_path}/common

    mkdir -p #{tomcat_path}/shared/classes
    chown -R root:tomcat #{tomcat_path}/shared
    chmod -R 771 #{tomcat_path}/shared

    mkdir -p #{tomcat_path}/server/classes
    chown -R root:tomcat #{tomcat_path}/server
    chmod -R 771 #{tomcat_path}/server

    chown -R tomcat:tomcat #{tomcat_path}
  EOH
end

# Replace default-java symlink.
bash "replace_java_symlink" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    rm -rf /usr/lib/jvm/default-java
    ln -s /usr/lib/jvm/java-#{java_version}-oracle /usr/lib/jvm/default-java
  EOH
end

cron "logrotate_cron" do
  minute "0,15,30,45"
  user "root"
  command "/usr/sbin/logrotate /etc/logrotate.conf"
end

cookbook_file "tomcat" do
  path "/etc/logrotate.d/tomcat"
  source "logrotate.tomcat"
  mode "0644"
  owner "root"
  group "root"
end

# Content moved into tomcat logrotate conf
file "/etc/logrotate.d/syslog" do
  action :delete
end

# Perform daily purge of access logs (they are sent to logstash, no need to retain).
cookbook_file "purge_access_logs" do
  path "/etc/cron.daily/purge_access_logs"
  source "purge_access_logs"
  mode "0755"
  owner "root"
  group "root"
end

# Enabling json logs over syslog
cookbook_file "02-java-logs.conf" do
  path "/etc/rsyslog.d/02-java-logs.conf"
  source "rsyslog-java-logs.conf"
  mode "0600"
  owner "root"
  group "root"
end

cookbook_file "03-tomcat-access.conf" do
  path "/etc/rsyslog.d/03-tomcat-access.conf"
  source "rsyslog-tomcat-access.conf"
  mode "0600"
  owner "root"
  group "root"
end

service "rsyslog" do
  action :restart
end

# Need to Install Postfix BEFORE We Remove Sendmail, Otherwise We Lose Important Packages (Like Cron)
yum_package "postfix" do
  action :install
  flush_cache [:before]
  only_if { node['email']['install'] == "yes" }
end

yum_package "sendmail" do
  action :remove
  flush_cache [:before]
  only_if { node['email']['install'] == "yes" }
end

service "postfix" do
  action [ :disable, :stop]
  only_if { node['email']['install'] == "yes" }
end

# Install nginx
yum_package "nginx" do
  action :install
  flush_cache [:before]
end

# Create nginx configuration
cookbook_file "nginx.conf" do
  path "/etc/nginx/nginx.conf"
  source "nginx.conf"
  mode "0600"
  owner "nginx"
  group "nginx"
end

cookbook_file "nginx.init" do
  path "/etc/init.d/nginx"
  source "nginx.init"
  mode "0755"
  owner "root"
  group "root"
end

# Make Directories for Pid and Lock File
directory '/var/lock/subsys/nginx' do
  owner 'nginx'
  group 'nginx'
  mode '0755'
  action :create
end

directory '/var/run/nginx' do
  owner 'nginx'
  group 'nginx'
  mode '0755'
  action :create
end

chef_gem "aws-sdk" do
  action [:install, :upgrade]
  compile_time false
end
