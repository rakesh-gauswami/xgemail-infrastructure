#============================================================================
#
# logrotate_logstash_forwarder.rb
#
#============================================================================
#
# Rotate the LogStash Forwarder Logs.
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
#============================================================================

#----------------------------------------------------------------------------
# CONFIG
#----------------------------------------------------------------------------

cookbook_file '/etc/logrotate.d/logstashforwarder' do
  source 'logstashforwarder.logrotate'
  owner 'root'
  group 'root'
  mode 0644
end