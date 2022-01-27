#
# Cookbook Name:: sophos-cloud-mount
# Attribute:: default
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

default[:mount][:luks_password_dir] = "/root/etc"
default[:mount][:volumes] = []

default['sophos_cloud']['sdb_region'] = 'us-west-2'