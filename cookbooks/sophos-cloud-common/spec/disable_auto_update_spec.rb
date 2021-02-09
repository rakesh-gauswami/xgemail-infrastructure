#=============================================================================
#
# disable_auto_update_spec.rb
#
#=============================================================================
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
#=============================================================================

# Use a common spec helper for all cookbooks.
require File.expand_path('../../../../lib/spec_helper.rb', __FILE__)

describe 'sophos-cloud-common::disable_auto_update' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  it 'creates cookbook_file 90-repo-upgrade-none.cfg' do
    expect(chef_run).to create_cookbook_file('90-repo-upgrade-none.cfg').with(
      path: '/etc/cloud/cloud.cfg.d/90-repo-upgrade-none.cfg',
      source: '90-repo-upgrade-none.cfg',
      mode: '0600',
      owner: 'root',
      group: 'root',
    )
  end

end