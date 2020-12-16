#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: ami
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#

$SYSWIDE_ACCOUNT_NAM = node['sophos_cloud']['account'] || 'inf'
shcmd_h = Mixlib::ShellOut.new('echo -n $(runlevel 2>&1)')
runlevel = shcmd_h.run_command.stdout

MANUAL_TEST_RUN = ($SYSWIDE_ACCOUNT_NAM != 'hmr-core')
log "runlevel='#{runlevel}', $SYSWIDE_ACCOUNT_NAM=#{$SYSWIDE_ACCOUNT_NAM}, MANUAL_TEST_RUN=#{MANUAL_TEST_RUN}" do level :info end

# Ruby characters in strings can be referenced by their index number.
# This node attribute, coming in as jdk-1.8*, is selecting the seventh index which is 8 in this example.
java_version = "#{node['sophos_cloud']['jdk_version']}"[6]
sophos_script_path = node['sophos_cloud']['script_path']
sophos_tmp_path = node['sophos_cloud']['tmp']
sophos_thirdparty = node['sophos_cloud']['thirdparty']

directory sophos_script_path do
  mode '0755'
  owner 'root'
  group 'root'
  action :create
  recursive true
end

directory sophos_tmp_path do
  mode '0755'
  owner 'root'
  group 'root'
  action :create
  recursive true
end

# Add local IP to /etc/hosts
bash 'edit_etc_hosts' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
    echo "$(wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4) $(hostname)" >> /etc/hosts
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
bash 'remove_openjdk' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
    for p in $(yum list installed | awk '/openjdk/ {print $1}'); do
      yum remove -y $p
    done
  EOH
end

# Replace default-java symlink.
bash 'replace_java_symlink' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
    rm -rf /usr/lib/jvm/default-java
    ln -s /usr/lib/jvm/java-#{java_version}-oracle /usr/lib/jvm/default-java
  EOH
end

cron 'logrotate_cron' do
  minute '0,15,30,45'
  user 'root'
  command '/usr/sbin/logrotate /etc/logrotate.conf'
end

chef_gem 'aws-sdk' do
  action [:install, :upgrade]
  compile_time false
end

# Install packages for all supported file systems.

yum_package 'xfsprogs' do
  action :install
end

yum_package 'amazon-ssm-agent' do
  action :upgrade
end

# Packages required by postfix 2.4.1.2:

yum_package 'libuuid' do
  action :upgrade
end

SOPHOS_BIN_DIR = '/opt/sophos/bin'
PACKAGES_DIR = '/opt/sophos/packages'
DEPLOYMENT_DIR = '/opt/sophos/xgemail'

JILTER_INBOUND_VERSION = node['xgemail']['jilter_inbound_version']
JILTER_INBOUND_PACKAGE_NAME = "xgemail-jilter-inbound-#{JILTER_INBOUND_VERSION}"

JILTER_OUTBOUND_VERSION = node['xgemail']['jilter_outbound_version']
JILTER_OUTBOUND_PACKAGE_NAME = "xgemail-jilter-outbound-#{JILTER_OUTBOUND_VERSION}"

JILTER_ENCRYPTION_VERSION = node['xgemail']['jilter_encryption_version']
JILTER_ENCRYPTION_PACKAGE_NAME = "xgemail-jilter-encryption-#{JILTER_ENCRYPTION_VERSION}"

JILTER_DELIVERY_VERSION = node['xgemail']['jilter_delivery_version']
JILTER_DELIVERY_PACKAGE_NAME = "xgemail-jilter-delivery-#{JILTER_DELIVERY_VERSION}"

POSTFIX3_RPM = "postfix3-sophos-#{node['xgemail']['postfix3_version']}.el6.x86_64.rpm"

directory SOPHOS_BIN_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory PACKAGES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory DEPLOYMENT_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

cookbook_file "#{SOPHOS_BIN_DIR}/ebs-delete-on-termination.py" do
  source 'ebs-delete-on-termination.py'
  mode '0755'
  owner 'root'
  group 'root'
end

execute 'download_jilter_inbound' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      aws --region us-west-2 s3 cp s3:#{sophos_thirdparty}/xgemail/#{JILTER_INBOUND_PACKAGE_NAME}.tar .
  EOH
end

execute 'extract_jilter_inbound_package' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      tar xf #{JILTER_INBOUND_PACKAGE_NAME}.tar -C #{DEPLOYMENT_DIR}
  EOH
end

# Create a sym link to xgemail-jilter-inbound
link "#{DEPLOYMENT_DIR}/xgemail-jilter-inbound" do
   to "#{DEPLOYMENT_DIR}/#{JILTER_INBOUND_PACKAGE_NAME}"
end

execute 'download_jilter_outbound' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      aws --region us-west-2 s3 cp s3:#{sophos_thirdparty}/xgemail/#{JILTER_OUTBOUND_PACKAGE_NAME}.tar .
  EOH
end

execute 'extract_jilter_outbound_package' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      tar xf #{JILTER_OUTBOUND_PACKAGE_NAME}.tar -C #{DEPLOYMENT_DIR}
  EOH
end

# Create a sym link to xgemail-jilter-outbound
link "#{DEPLOYMENT_DIR}/xgemail-jilter-outbound" do
  to "#{DEPLOYMENT_DIR}/#{JILTER_OUTBOUND_PACKAGE_NAME}"
end

execute 'download_jilter_encryption' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      aws --region us-west-2 s3 cp s3:#{sophos_thirdparty}/xgemail/#{JILTER_ENCRYPTION_PACKAGE_NAME}.tar .
  EOH
end

execute 'extract_jilter_encryption_package' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      tar xf #{JILTER_ENCRYPTION_PACKAGE_NAME}.tar -C #{DEPLOYMENT_DIR}
  EOH
end


# Create conf directories
directory "#{DEPLOYMENT_DIR}/#{JILTER_INBOUND_PACKAGE_NAME}/conf" do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory "#{DEPLOYMENT_DIR}/#{JILTER_OUTBOUND_PACKAGE_NAME}/conf" do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

# Write launch darkly application properties
%w(inf dev dev3 qa prod).each do | cur |

  template "launch_darkly_#{cur}.properties" do
    path "#{DEPLOYMENT_DIR}/#{JILTER_OUTBOUND_PACKAGE_NAME}/conf/launch_darkly_#{cur}.properties"
    source 'jilter-launch-darkly.properties.erb'
    mode '0700'
    variables(
        :launch_darkly_key => node['xgemail']["launch_darkly_#{cur}"]
    )
  end

  template "launch_darkly_#{cur}.properties" do
    path "#{DEPLOYMENT_DIR}/#{JILTER_INBOUND_PACKAGE_NAME}/conf/launch_darkly_#{cur}.properties"
    source 'jilter-launch-darkly.properties.erb'
    mode '0700'
    variables(
        :launch_darkly_key => node['xgemail']["launch_darkly_#{cur}"]
    )
  end

end


# Create a sym link to xgemail-jilter-encryption
link "#{DEPLOYMENT_DIR}/xgemail-jilter-encryption" do
  to "#{DEPLOYMENT_DIR}/#{JILTER_ENCRYPTION_PACKAGE_NAME}"
end


execute 'download_jilter_delivery' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
  curl -X GET "https://delivery-jilter-tar.s3.eu-west-1.amazonaws.com/xgemail-jilter-delivery-0.1.1-SNAPSHOT.tar?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAUEGAP77VOPAKSXX3%2F20201216%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20201216T050055Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEGMaCXVzLWVhc3QtMSJIMEYCIQCuQ0SBqtV62MBcTbl5na%2BWrbHarNfNRQliCe82DzY6EQIhAO6hGQYUzt4405jSy7tRAEnS6ArMfFvvOUoe3JH11omLKqMDCPz%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEQABoMMjgzODcxNTQzMjc0IgyD82NPLyZ5dDG%2BSsYq9wLGTT8lYNwBYNHiT%2FxTA1n2NWeulOtsFXqUOUoijtUnHpmjRS3g%2FkIRKEt%2FSHRf9xxOgrmRg%2Fm1kqen8aWQq0edzIktSIcWZd1qSazab8rrNKvdudJxY1OBwpV2OrguwHBG7u2321rDgTXOQy5qSaH4RQkYZGkYdrwHC%2Bc5pFj%2B2OhmOrP9gy96EJl1stER2O5Q6dF67wePI%2Fkw2XJ8SHOodoxr8h%2FWdPho4%2BdK65ZbMRd4m8OevcPfs7o31gPn9q2dFEyk7%2BWoQ0YZ5QkTbydG0Ibd9vMsUqUBmicoPhPxYQZmf%2BqN3FGjC%2Fsbu9TyjViKFvIutcChoC6xa645nNtRczsVCUeVkvcQveYNAstgiQlwb33pkaPW%2B2VdkOzJdViEMkrWHc6XJCpPDUa5j44J7QxZWi1v0RXgI8QfZmNYPqq2hTI6gJKKc42tWwyFPf%2F8uk%2FuYhr8VzY8oHPOvoxn9Hg%2FgXQmhzcVsIIaPEyKB%2BmnBcpDAF0wu%2B3l%2FgU6pQFcoSpYF%2Blrf2M0xXfL3s2jmWrjOyUOKlWpP6s4%2F2XtNNN9nyUFGsRSC3QIY%2FxYjvO%2F9Kjv1JQYvcRxdu8ZaydgBwCWdgCBBiWk4Ou9pTLrhiI1x43k5YjRu1Z7HUoyydkE4z75E%2BlbhNew5rDSKSy7L33%2B%2FkcP1G3kNSZwoIiMxha22bADw%2Be3MCSoRQEN4UM%2FpDti3XKkGnvWG9qCg2vQ%2FFMIgVw%3D&X-Amz-Signature=e67e63df74b5a298ed4ae6f87ebba5923436c5b2aea73c38850795cb6fb8be8c" -o xgemail-jilter-delivery-0.1.1-SNAPSHOT.tar
  EOH
end

execute 'extract_jilter_delivery_package' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      tar xf #{JILTER_DELIVERY_PACKAGE_NAME}.tar -C #{DEPLOYMENT_DIR}
  EOH
end


link "#{DEPLOYMENT_DIR}/xgemail-jilter-delivery" do
  to "#{DEPLOYMENT_DIR}/#{JILTER_DELIVERY_PACKAGE_NAME}"
end

execute 'remove_postfix_package' do
  command 'rpm -e --nodeps postfix'
  ignore_failure true
end

execute 'download_postfix3-sophos-rpm' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      aws --region us-west-2 s3 cp s3:#{sophos_thirdparty}/xgemail/#{POSTFIX3_RPM} .
  EOH
end

rpm_package 'install postfix3-sophos' do
  action :install
  package_name "#{POSTFIX3_RPM}"
  source "#{PACKAGES_DIR}/#{POSTFIX3_RPM}"
end

execute 'enable_postfix_service' do
  user 'root'
  command 'chkconfig --level 2345 postfix on'
end

execute 'add ipaddress module' do
  user 'root'
  command 'pip install ipaddress'
end

yum_package 'sendmail' do
  action :remove
  flush_cache [:before]
end

# Install Sophos Anti-Virus.
bash 'install_savi_client' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
    set -e

    mkdir -p /tmp/savi
    aws --region us-west-2 s3 cp s3:#{node['sophos_cloud']['savi']} /tmp/savi
    tar -xzvf /tmp/savi/savi-install.tar.gz -C /tmp/savi/

    pushd /tmp/savi/savi-install
    bash install.sh
    popd

    rm -rf /tmp/savi /tmp/savi-install.tar.gz
  EOH
end

SYSCTL_FILE = '/etc/sysctl.d/01-xgemail.conf'
LOAD_SYSCTL_PARAMETERS = "/sbin/sysctl -p '#{SYSCTL_FILE}'"

execute LOAD_SYSCTL_PARAMETERS do
  action :nothing
end

template SYSCTL_FILE do
  source 'sysctl.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  variables(
    :SYSCTL_IP_LOCAL_PORT_RANGE => node['xgemail']['sysctl_ip_local_port_range'],
    :SYSCTL_NETDEV_MAX_BACKLOG => node['xgemail']['sysctl_netdev_max_backlog'],
    :SYSCTL_OPTMEM_MAX => node['xgemail']['sysctl_optmem_max'],
    :SYSCTL_SWAPPINESS => node['xgemail']['sysctl_swappiness'],
    :SYSCTL_RMEM_MAX => node['xgemail']['sysctl_rmem_max'],
    :SYSCTL_WMEM_MAX => node['xgemail']['sysctl_wmem_max'],
    :SYSCTL_RMEM_DEFAULT => node['xgemail']['sysctl_rmem_default'],
    :SYSCTL_WMEM_DEFAULT => node['xgemail']['sysctl_wmem_default'],
    :SYSCTL_TCP_RMEM => node['xgemail']['sysctl_tcp_rmem'],
    :SYSCTL_TCP_WMEM => node['xgemail']['sysctl_tcp_wmem'],
    :SYSCTL_TCP_FIN_TIMEOUT => node['xgemail']['sysctl_tcp_fin_timeout'],
    :SYSCTL_TCP_MAX_SYN_BACKLOG => node['xgemail']['sysctl_tcp_max_syn_backlog'],
    :SYSCTL_TCP_MAX_TW_BUCKETS => node['xgemail']['sysctl_tcp_max_tw_buckets'],
    :SYSCTL_TCP_SLOW_START_AFTER_IDLE => node['xgemail']['sysctl_tcp_slow_start_after_idle'],
    :SYSCTL_TCP_TW_REUSE => node['xgemail']['sysctl_tcp_tw_reuse'],
    :SYSCTL_TCP_WINDOW_SCALING => node['xgemail']['sysctl_tcp_window_scaling']
  )
  notifies :run, "execute[#{LOAD_SYSCTL_PARAMETERS}]", :immediately
end
