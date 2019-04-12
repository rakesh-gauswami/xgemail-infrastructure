#
# Cookbook Name: sophos-cloud-fluentd
# Attribute: sandbox
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# These attributes overwrite default settings for sandbox
#
#
# Sandbox settings
ENVIRONMENT = ENV['DEFAULT_ENVIRONMENT']
INSTANCE_TYPE = ENV['INSTANCE_TYPE']

if ENVIRONMENT == "sandbox"
  default['sophos_cloud']['region']      = ENV['DEFAULT_REGION']
  default['fluentd']['tdagent_version']  = '3.0.0-0'
end
