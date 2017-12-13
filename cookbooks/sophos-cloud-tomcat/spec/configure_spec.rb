#=============================================================================
#
# configure_spec.rb
#
#=============================================================================
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
#=============================================================================

require 'spec_helper'

describe 'sophos-cloud-tomcat::configure' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'creates /usr/share/tomcat/bin/setenv.sh' do
    expect(chef_run).to create_template('/usr/share/tomcat/bin/setenv.sh').with(
      mode: '0444',
      owner: 'root',
      group: 'tomcat',
    )
  end

  it 'downloads properties files' do
    expect(chef_run).to run_bash('download_application_and_bootstrap_properties').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

  it 'fixes permissions on properties files' do
    expect(chef_run).to run_bash('restore_permissions_bootstrap_properties').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

end
