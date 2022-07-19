#=============================================================================
#
# deploy_snmpd_conf_spec.rb
#
#=============================================================================
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
#=============================================================================

#----------------------------------------------------------------------------
# HELPER
#----------------------------------------------------------------------------
require File.expand_path('../../../../lib/spec_helper.rb', __FILE__)

#----------------------------------------------------------------------------
# SPEC
#----------------------------------------------------------------------------
describe 'sophos-cloud-snmpd::deploy_snmpd_conf' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['sophos_cloud']['connections'] = 'cloud-inf-connections'
      node.set['sophos_cloud']['region'] = 'us-west-2'
      node.set['sophos_cloud']['vpc_name'] = 'CloudStation'
    end.converge(described_recipe)
  end

  it 'installs chef_gem aws-sdk' do
    expect(chef_run).to install_chef_gem('aws-sdk')
  end

  it 'creates template snmpd.conf' do
    expect(chef_run).to create_template('snmpd.conf').with(
      path: '/etc/snmp/snmpd.conf',
      source: 'snmpd.conf.erb',
      mode: '0600',
      owner: 'root',
      group: 'root',
    )
  end

  SNMP_FILES = %w[
    /etc/snmp/snmp.conf
    /etc/snmp/snmptrapd.conf
  ]

  SNMP_FILES.each do |file|
    it 'creates directory' do
      expect(chef_run).to create_file(file).with(
        mode: '0600',
        owner: 'root',
        group: 'root',
      )
    end
  end

end
