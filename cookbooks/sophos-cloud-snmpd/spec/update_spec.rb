#=============================================================================
#
# update_spec.rb
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
describe 'sophos-cloud-snmpd::update' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  before do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_call_original
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('sophos-cloud-snmpd::deploy_snmpd_conf')
  end

  it 'includes recipe sophos-cloud-snmpd::deploy_snmpd_conf' do
    expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('sophos-cloud-snmpd::deploy_snmpd_conf')
    chef_run
  end

  it 'stops service snmpd' do
    expect(chef_run).to stop_service('snmpd')
  end

  it 'starts service snmpd' do
    expect(chef_run).to start_service('snmpd')
  end

end
