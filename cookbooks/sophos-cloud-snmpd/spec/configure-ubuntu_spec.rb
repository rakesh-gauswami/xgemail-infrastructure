#=============================================================================
#
# configure-ubuntu_spec.rb
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
describe 'sophos-cloud-snmpd::configure-ubuntu' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  before do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('sophos-cloud-snmpd::deploy_snmpd_conf_ubuntu')
  end

  it 'installs package snmp' do
    expect(chef_run).to install_package('snmp')
  end

  it 'installs package snmpd' do
    expect(chef_run).to install_package('snmpd')
  end

  it 'includes recipe sophos-cloud-snmpd::deploy_snmpd_conf_ubuntu' do
    expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('sophos-cloud-snmpd::deploy_snmpd_conf_ubuntu')
    chef_run
  end

  it 'restarts service snmpd' do
    expect(chef_run).to restart_service('snmpd')
  end

end
