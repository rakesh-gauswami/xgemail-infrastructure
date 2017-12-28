#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure_postfix_snmp_logicmonitor
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure SNMP to extend Postfix queues to LogicMonitor

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

# Ensure all required packages are installed before proceeding
# with installation
package 'net-snmp-perl'
package 'perl-DB_File'
package 'perl-File-Tail'

# Create directory for scripts
directory '/usr/local/logicmonitor/utils' do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
end

NODE_TYPE = node['xgemail']['cluster_type']

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

template 'postfixStats-reporter.pl' do
    path '/usr/local/logicmonitor/utils/postfixStats-reporter.pl'
    source 'postfixStats-reporter.pl.erb'
    mode '0755'
    owner 'root'
    group 'root'
    variables(
            :instance_name => INSTANCE_NAME
    )
end

template 'postfixStats-updater.pl' do
    path '/usr/local/logicmonitor/utils/postfixStats-updater.pl'
    source 'postfixStats-updater.pl.erb'
    mode '0755'
    owner 'root'
    group 'root'
    variables(
            :instance_name => INSTANCE_NAME
    )
end

cookbook_file '/etc/init.d/postfixStats' do
    path '/etc/init.d/postfixStats'
    source 'postfixStats.init'
    mode '0755'
    owner 'root'
    group 'root'
    action :create
end

# Add and start postfixStats service
service 'postfixStats' do
    action [ :enable, :start ]
end