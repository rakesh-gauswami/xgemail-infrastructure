#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: ami
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

$SYSWIDE_ACCOUNT_NAM = node['sophos_cloud']['account'] || 'inf'
shcmd_h = Mixlib::ShellOut.new('echo -n $(runlevel 2>&1)')
runlevel = shcmd_h.run_command.stdout

MANUAL_TEST_RUN = ($SYSWIDE_ACCOUNT_NAM != 'hmr-core')
log "runlevel='#{runlevel}', $SYSWIDE_ACCOUNT_NAM=#{$SYSWIDE_ACCOUNT_NAM}, MANUAL_TEST_RUN=#{MANUAL_TEST_RUN}" do level :info end

execute 'install_ghetto_forge_repo' do
  user 'root'
  command 'yum install -y http://mirror.ghettoforge.org/distributions/gf/el/6/gf/x86_64/gf-release-6-10.gf.el6.noarch.rpm'
  creates '/etc/yum.repos.d/gf.repo'
end

execute 'remove_postfix_package' do
  command 'rpm -e --nodeps postfix'
  ignore_failure true
end

yum_package 'postfix3' do
  action :install
  options '--enablerepo=gf-plus'
end

execute 'enable_postfix_service' do
  user 'root'
  command 'chkconfig --level 2345 postfix on'
end

# Install packages for all supported file systems.

yum_package 'xfsprogs' do
  action :install
end



PACKAGES_DIR = '/opt/sophos/packages'
JILTER_INBOUND_VERSION = node['xgemail']['jilter_inbound_version']
JILTER_INBOUND_PACKAGE_NAME = "xgemail-jilter-inbound-#{JILTER_INBOUND_VERSION}"

JILTER_OUTBOUND_VERSION = node['xgemail']['jilter_outbound_version']
JILTER_OUTBOUND_PACKAGE_NAME = "xgemail-jilter-outbound-#{JILTER_OUTBOUND_VERSION}"

directory PACKAGES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

execute 'download_jilter_inbound' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      aws --region us-west-2 s3 cp s3://cloud-applications-3rdparty/xgemail/#{JILTER_INBOUND_PACKAGE_NAME}.tar .
  EOH
end


execute 'download_jilter_outbound' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      aws --region us-west-2 s3 cp s3://cloud-applications-3rdparty/xgemail/#{JILTER_OUTBOUND_PACKAGE_NAME}.tar .
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
