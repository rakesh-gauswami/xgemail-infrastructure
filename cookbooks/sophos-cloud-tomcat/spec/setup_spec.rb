#=============================================================================
#
# setup_spec.rb
#
#=============================================================================
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
#=============================================================================

require 'spec_helper'

describe 'sophos-cloud-tomcat::setup' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'creates various directories' do
    expect(chef_run).to create_directory('/data/etc').with(mode: '0755')
    expect(chef_run).to create_directory('/data/log/tomcat').with(mode: '0755')
    expect(chef_run).to create_directory('/data/tmp').with(mode: '0755')
    expect(chef_run).to create_directory('/data/var/webapps').with(mode: '0755')
    expect(chef_run).to create_directory('/usr/local/etc/sophos').with(mode: '0755')
    expect(chef_run).to create_directory('/var/run/tomcat').with(mode: '0755')
  end

  it 'sets up iptables' do
    expect(chef_run).to run_bash('setup_iptables').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

  it 'installs Oracle JDK7' do
    expect(chef_run).to run_bash('install_oracle_jdk7').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

  it 'installs tomcat' do
    expect(chef_run).to run_bash('install_tomcat').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

  it 'suppresses tomcat warnings' do
    expect(chef_run).to run_bash('suppress_tomcat_warnings').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

  it 'creates /etc/logrotate.d/tomcat' do
    expect(chef_run).to create_cookbook_file('/etc/logrotate.d/tomcat').with(
      mode: '0644',
      owner: 'root',
      group: 'root',
    )
  end

  it 'creates logrotate crontab entry' do
    expect(chef_run).to create_cron('logrotate_cron')
  end

  it 'creates /etc/cron.daily/purge_access_logs' do
    expect(chef_run).to create_cookbook_file('/etc/cron.daily/purge_access_logs').with(
      mode: '0755',
      owner: 'root',
      group: 'root',
    )
  end

  it 'creates /etc/rsyslog.d/02-java-logs.conf' do
    expect(chef_run).to create_cookbook_file('/etc/rsyslog.d/02-java-logs.conf').with(
      mode: '0600',
      owner: 'root',
      group: 'root',
    )
  end

  it 'creates /etc/rsyslog.d/03-tomcat-access.conf' do
    expect(chef_run).to create_cookbook_file('/etc/rsyslog.d/03-tomcat-access.conf').with(
      mode: '0600',
      owner: 'root',
      group: 'root',
    )
  end

  it 'restarts service rsyslog' do
    expect(chef_run).to restart_service('rsyslog')
  end

  it 'installs snmp packages' do
    expect(chef_run).to install_package('net-snmp')
  end

  it 'creates /etc/snmp/snmpd.conf' do
    expect(chef_run).to create_template('/etc/snmp/snmpd.conf').with(
      mode: '0600',
      owner: 'root',
      group: 'root',
    )
  end

  it 'creates empty files /etc/snmp/snmp.conf and /etc/snmp/snmptrapd.conf' do
    expect(chef_run).to create_file('/etc/snmp/snmp.conf').with(
      mode: '0600',
      owner: 'root',
      group: 'root',
    )
    expect(chef_run).to create_file('/etc/snmp/snmptrapd.conf').with(
      mode: '0600',
      owner: 'root',
      group: 'root',
    )
  end

  it 'starts service snmpd' do
    expect(chef_run).to start_service('snmpd')
  end
end
