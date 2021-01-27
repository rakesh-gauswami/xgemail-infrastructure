#=============================================================================
#
# configure_auditd_spec.rb
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
describe 'sophos-cloud-common::configure_auditd' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  it 'creates file audit.rules.default' do
    expect(chef_run).to delete_file('audit.rules.default').with(
      path: '/etc/audit/rules.d/audit.rules.default',
      action: [ :delete ],
    )
  end

  it 'creates template auditd configuration file' do
    expect(chef_run).to create_template('auditd configuration file').with(
      path: '/etc/audit/auditd.conf',
      source: 'etc-audit-auditd.conf.erb',
      mode: '0640',
      owner: 'root',
      group: 'root',
    )
  end

  it 'creates template auditd rules file' do
    expect(chef_run).to create_template('auditd rules file').with(
      path: '/etc/audit/audit.rules',
      source: 'etc-audit-audit.rules.erb',
      mode: '0640',
      owner: 'root',
      group: 'root',
    )
  end

  it 'runs ruby_block to enable auditing for processes that start prior to auditd' do
    expect(chef_run).to run_ruby_block('enable auditing for processes that start prior to auditd')
  end

end
