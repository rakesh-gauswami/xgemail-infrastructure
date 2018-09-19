#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_supervisor
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

yum_package 'monit' do
  action :install
end

cookbook_file '/etc/monit.conf' do
  source 'monit.conf'
  mode '0600'
  owner 'root'
  group 'root'
end

cookbook_file '/etc/logrotate.d/monit' do
  source 'logrotate-monit.conf'
  mode '0644'
  owner 'root'
  group 'root'
end

# Configure monit to log to syslog.
file '/etc/monit.d/logging' do
  content 'set logfile syslog facility log_daemon'
  mode '0600'
  owner 'root'
  group 'root'
  action :create
end

# Add rsyslog config file to redirect lifecycle messages to its own log file.
file '/etc/rsyslog.d/02-monit.conf' do
  content "if $programname == 'monit' then /var/log/monit\n& ~"
  mode '0644'
  owner 'root'
  group 'root'
end

# Leave Monit service disabled and stopped.
service 'monit' do
    action [ :disable, :stop ]
end