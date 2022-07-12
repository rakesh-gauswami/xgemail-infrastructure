#
# Cookbook Name:: sophos-cloud-ntpd
# Attribute:: default
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

case node[:platform]
  when "redhat","centos","fedora"
    default[:ntp][:service] = "ntpd"
  when "ubuntu","debian"
    default[:ntp][:service] = "ntp"
  else
    default[:ntp][:service] = "ntpd"
end

default[:ntp][:servers] = [
    '0.amazon.pool.ntp.org',
    '1.amazon.pool.ntp.org',
    '2.amazon.pool.ntp.org'
]

default[:ntp][:restrict] = [
    '127.0.0.1',
    '::1'
]
