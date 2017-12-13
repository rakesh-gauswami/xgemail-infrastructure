#=============================================================================
#
# deploy_certs_spec.rb
#
#=============================================================================
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
#=============================================================================

require 'spec_helper'

describe 'sophos-cloud-tomcat::deploy_certs' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'adds mongodb certificate to keystore' do
    expect(chef_run).to run_bash('add_mongodb_to_keystore').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

  it 'adds iapi certificate to keystore' do
    expect(chef_run).to run_bash('add_iapi_to_keystore').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

  it 'adds hub certificate to keystore' do
    expect(chef_run).to run_bash('add_hub_to_keystore').with(
      user: 'root',
      cwd:  '/tmp',
    )
  end

end
