#=============================================================================
#
# default_spec.rb
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
describe 'sophos-cloud-ntpd::default' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['ntp']['service'] = 'ntp'
    end.converge(described_recipe)
  end

  it 'installs package ntp' do
    expect(chef_run).to install_package('ntp')
  end

  it 'creates cookbook_file /tmp/vpc_detail.sh if missing' do
    expect(chef_run).to create_cookbook_file_if_missing('/tmp/vpc_detail.sh').with(
      source: 'vpc_detail.sh',
      mode: '0755',
      owner: 'root',
      group: 'root',
      action: [ :create_if_missing ],
    )
  end

  it 'executes vpc_detail.sh' do
    expect(chef_run).to run_execute('vpc_detail file')
  end

  it 'runs ruby_block replace VPC CIDR in attribute variable' do
    expect(chef_run).to run_ruby_block('Replace vpc cidr in attribute variable')
  end

  it 'creates template /etc/ntp.conf' do
    expect(chef_run).to create_template('/etc/ntp.conf').with(
      source: 'ntp.conf.erb',
    )
  end

  it 'enables service ntp' do
    expect(chef_run).to enable_service('ntp').with(
      service_name: 'ntp',
      action: [ :enable, :restart ],
    )
  end

  it 'restarts service ntp' do
    expect(chef_run).to restart_service('ntp').with(
      service_name: 'ntp',
      action: [ :enable, :restart ],
    )
  end

end
