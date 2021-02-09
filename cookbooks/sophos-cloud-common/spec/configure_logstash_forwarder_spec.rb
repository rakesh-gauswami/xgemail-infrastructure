#=============================================================================
#
# configure_logstash_forwarder_spec.rb
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

describe 'sophos-cloud-common::configure_logstash_forwarder' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['mail_logs'] = 'False'
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['nginx_logs'] = 'False'
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['custom_logs'] = 'False'
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['logstash_server'] = ''
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['logstash_timeout'] = 10
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['instance_log_path'] = '/data/log/*'
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['instance_log_type'] = 'applog'
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['sophos_logs'] = 'False'
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['sophos_log_path'] = '/data/log/*'
      node.set['sophos_cloud_common']['configure_logstash_forwarder']['sophos_log_type'] = 'applog'
      node.set['sophos_cloud']['environment'] = 'inf'
      node.set['sophos_cloud']['local_key_path'] = '/etc/ssl/private'
      node.set['sophos_cloud']['region'] = 'us-west-2'
      node.set['sophos_cloud']['tmp'] = '/tmp/sophos'
      node.set['sophos_cloud']['vpc_name'] = 'CloudStation'
    end.converge(described_recipe)
  end

  it 'creates directory /tmp/sophos/certificates' do
    expect(chef_run).to create_directory('/tmp/sophos/certificates').with(
      mode: '0755',
      owner: 'root',
      group: 'root',
      recursive: true,
      action: [ :create ],
    )
  end

  it 'creates directory /etc/ssl/private' do
    expect(chef_run).to create_directory('/etc/ssl/private').with(
      mode: '0755',
      owner: 'root',
      group: 'root',
      recursive: true,
      action: [ :create ],
    )
  end

  it 'deletes file /tmp/sophos/certificates/inf-connection-logstash-forwarder.tar.gz' do
    expect(chef_run).to delete_file('/tmp/sophos/certificates/inf-connection-logstash-forwarder.tar.gz').with(
      action: [ :delete ],
    )
  end

  it 'writes a log with info level logging' do
    expect(chef_run).to write_log('Download from S3://cloud-inf-connections/us-west-2/CloudStation/inf-connection-logstash-forwarder.tar.gz to /tmp/sophos/certificates').with(
      level: [ :info ],
    )
  end

  it 'downloads an existing logstash keypair and certificate' do
    expect(chef_run).to run_bash('download_existing_logstash_keypair_and_cert').with(
      user: 'root',
      cwd: '/tmp/sophos/certificates'
                        )
  end

end
