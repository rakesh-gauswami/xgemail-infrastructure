#=============================================================================
#
# deploy_spec.rb
#
#=============================================================================
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
#=============================================================================

require 'spec_helper'

describe 'sophos-cloud-tomcat::deploy' do
  # FIXME write proper tests around node attributes
  # let(:chef_run) {
  #   ChefSpec::Runner.new do |node|
  #     node.set[:deploy] = [ 'appserver', 'iapi', 'transport', 'worker', 'svc_core' ]
  #
  #     it 'creates application.properties' do
  #       expect(chef_run).to create_template('application.properties').with(
  #         path: '/usr/local/etc/sophos/application.properties',
  #         source: 'application.properties.erb',
  #         mode: '0640',
  #         owner:  'root',
  #         group:  'tomcat7',
  #       )
  #     end
  #
  #     it 'creates application.properties' do
  #       expect(chef_run).to create_template('bootstrap.properties').with(
  #         path: '/usr/local/etc/sophos/bootstrap.properties',
  #         source: 'application.properties.erb',
  #         mode: '0640',
  #         owner:  'root',
  #         group:  'tomcat7',
  #       )
  #     end
  #
  #   end.converge(described_recipe)
  # }
end