#=============================================================================
#
# deploy_core_spec.rb
#
#=============================================================================
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
#=============================================================================

require 'spec_helper'

describe 'sophos-cloud-tomcat::deploy_core' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  # FIXME write proper tests around node attributes
  # it 'includes the sophos-cloud-tomcat::deploy recipe' do
  #   expect(chef_run).to include_recipe('sophos-cloud-tomcat::deploy')
  # end
  #
  # it 'adds Zero IAPI keys and Business Systems Integration CA to Java keystore' do
  #   expect(chef_run).to run_bash('add_core_to_keystore').with(
  #     user: 'root',
  #     cwd:  '/tmp',
  #   )
  # end
  #
  # it 'downloads the application' do
  #   expect(chef_run).to run_bash('download_core_war').with(
  #     user: 'root',
  #     cwd:  '/tmp',
  #   )
  # end

end