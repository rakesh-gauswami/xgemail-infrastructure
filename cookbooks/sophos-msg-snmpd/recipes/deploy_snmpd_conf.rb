#
# Cookbook Name:: sophos-msg-snmpd
# Recipe:: deploy_snmpd_conf -- this runs during and after AMI deployment
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Deploy configuration files for snmpd.

vpc_name = node[:sophos_cloud][:vpc_name]
region = node[:sophos_cloud][:region]

# Read snmpd username and password from logicmonitor.json file in S3.
# Don't abort if that file is not in S3, as we don't support Logic Monitor
# in every account.

bucket = node[:sophos_cloud][:connections]
s3_key = "#{region}/#{vpc_name}/logicmonitor.json"

chef_gem 'aws-sdk' do
  action [:install]
end

require 'aws-sdk'

s3 = ::Aws::S3::Client.new(region: 'us-west-2')

begin
  resp = s3.get_object(bucket: bucket, key: s3_key)
rescue ::Aws::S3::Errors::NoSuchKey => e
  Chef::Log.warn("Skipping snmpd setup: s3://#{bucket}/#{s3_key}: does not exist.")
rescue ::Aws::S3::Errors::AccessDenied => e
  Chef::Log.warn("Skipping snmpd setup: s3://#{bucket}/#{s3_key}: access denied.")
end  # Raise other exception types for analysis.

# If we can't get the snmp configuration data then there's nothing left to do.

return if resp == nil

# Configure SNMP.
decrypted_config = JSON.parse(resp.body.read)
template 'snmpd.conf' do
  path '/etc/snmp/snmpd.conf'
  source 'snmpd.conf.erb'
  variables({
    :snmp_user => decrypted_config['snmp_user'],
    :snmp_pass => decrypted_config['snmp_pass']
  })
  mode '0600'
  owner 'root'
  group 'root'
end

# Create empty snmp.conf and snmptrapd.conf files.
%w{/etc/snmp/snmp.conf /etc/snmp/snmptrapd.conf}.each do |f|
  file f do
    mode '0600'
    owner 'root'
    group 'root'
  end
end
