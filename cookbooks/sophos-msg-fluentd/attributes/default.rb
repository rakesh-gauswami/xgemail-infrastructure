#
# Cookbook Name:: sophos-msg-fluentd
# Attribute:: default
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Instead of literal constants, the "client" cookbook code should use
# values from the special three-dimensional map 'node', e.g.
#
#   x = #{node[k0][k1]}
#
# The value of #{node[k1][k2]} will come from two places:
#
#   (1) (if exists) a proper setting taken from the 'attributes.json'
#       file residing in the "script_path" (see below).
#
#   (2) (if (1) does not exist) the value, for the same keys 'k0' and
#       'k1', taken from the three-dimensional map 'default'
#
# The following populates the 'default' map.  Do not put in anything
# here that cannot be a reasonable default for all systems where these
# cookbooks are running; e.g. do not add the name of the "next host".


default['fluentd']['tdagent_version']         = '3.8.0-0.amazon2'
default['fluentd']['main_dir']                = '/etc/td-agent'
default['fluentd']['conf_dir']                = '/etc/td-agent.d'
default['fluentd']['patterns_dir']            = "#{node['fluentd']['main_dir']}/patterns"
default['fluentd']['plugin_dir']              = "#{node['fluentd']['main_dir']}/plugin"
default['fluentd']['sqs_delivery_delay']      = 240
