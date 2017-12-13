#=============================================================================
#
# create_image_spec.rb
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
describe 'sophos-cloud-ami::create_image' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  it 'creates template /tmp/create-image.sh' do
    expect(chef_run).to create_template('/tmp/create-image.sh').with(
      mode: '0644',
      owner: 'root',
      group: 'root',
    )
  end

  it 'installs aws libraries' do
    expect(chef_run).to run_bash('handle aws libraries').with(
      user: 'root',
    )
  end

  it 'runs script create_image.sh' do
    expect(chef_run).to run_bash('run create_image.sh').with(
      user: 'root',
    )
  end

end
