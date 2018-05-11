#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_cyren_service
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure CYREN service (ctasd) for XGEMAIL

# Only install on mail node

NODE_TYPE = node['sophos_cloud']['cluster']
if NODE_TYPE == 'mailinbound'

  # Ensure all required packages are installed before proceeding
  # with CYREN installation
  package 'wget'
  package 'tar'
  package 'net-snmp-perl'
  package 'perl-Time-HiRes'
  package 'perl-Sys-Syslog'

  # Constants
  CTASD_PACKAGE_VERSION = "#{node['xgemail']['ctasd_package_version']}"
  CTASD_PACKAGE_NAME = "ctasd-#{CTASD_PACKAGE_VERSION}"

  # Extract ctasd files
  execute 'extract ctasd files' do
    user 'root'
    cwd '/opt/sophos/packages'
    command <<-EOH
      tar xf #{CTASD_PACKAGE_NAME}.tar.gz
    EOH
  end

  # Create user for CYREN content filter handling
  user 'filter' do
    system true
    shell '/bin/false'
  end

  directory '/usr/lib/ctasd/snmp' do
    owner 'filter'
    group 'filter'
    mode '0755'
    recursive true
    action :create
  end

  directory '/etc/ctasd' do
    owner 'filter'
    group 'filter'
    mode '0755'
    action :create
  end

  directory '/var/run/ctasd' do
    owner 'filter'
    group 'filter'
    mode '0700'
    action :create
  end

  execute 'copy ctasd script' do
    command 'cp -f /opt/sophos/packages/cyren-ctasd/bin/ctasd /usr/lib/ctasd/ctasd'
  end

  execute 'copy ctasd binary' do
    command 'cp -f /opt/sophos/packages/cyren-ctasd/bin/ctasd.bin /usr/lib/ctasd/ctasd.bin'
  end

  execute 'copy ctasd libraries' do
    command 'cp -f /opt/sophos/packages/cyren-ctasd/bin/*.so /usr/lib/ctasd/'
  end

  execute 'copy snmp files' do
    command 'cp -rf /opt/sophos/packages/cyren-ctasd/bin/snmp/* /usr/lib/ctasd/snmp/'
  end

  template 'copy ctasd config file' do
    path '/etc/ctasd/ctasd.conf'
    source 'ctasd.conf.erb'
    mode '0600'
    owner 'filter'
    group 'filter'
    variables(
      :CTASD_LICENSE_KEY => node['xgemail']['ctasd_license_key'],
      :CTASD_SERVER_ADDRESS => node['xgemail']['ctasd_server_address']
    )
  end

  template 'copy ctasd init file' do
    path '/etc/init.d/ctasd'
    source 'ctasd.init.erb'
    mode '0755'
    owner 'filter'
    group 'filter'
    variables(
      :CTASD_DAEMON_STOP_TIMEOUT => node['xgemail']['ctasd_daemon_stop_timeout'],
      :CTASD_AGENT_STOP_TIMEOUT => node['xgemail']['ctasd_agent_stop_timeout'],
      :CTASD_AGENT_OID => node['xgemail']['ctasd_agent_oid'],
      :CTASD_AGENT_HAVE_SNMP => node['xgemail']['ctasd_agent_have_snmp']
    )
  end

  # Cleanup
  file "/opt/sophos/packages/#{CTASD_PACKAGE_NAME}.tar.gz" do
    action :delete
  end

  directory '/opt/sophos/packages/cyren-ctasd' do
    recursive true
    action :delete
  end

  # Start ctasd on startup
  execute 'run ctasd on startup' do
    command 'chkconfig ctasd on'
  end

  # Restart service
  service 'ctasd' do
    action :restart
  end

else

  log "Skipped CYREN installation for non-mail instance #{node['sophos_cloud']['cluster']}." do
    level :info
  end

end
