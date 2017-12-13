#===========================================================================
#
# prepare_jeeves.rb
#
#===========================================================================
#
# Compose Event Service
#
# Copyright 2017, Sophos
#
# All rights reserved - Do Not Redistribute
#
#===========================================================================

USERNAME = 'jeeves'
TOMCAT_USER = 'tomcat'
TOMCAT_GROUP = 'tomcat'

# Add jeeves to tomcat group
group TOMCAT_GROUP do
  members USERNAME
  append true
  action :modify
end

# Set director owner to tomcat user with read permissions for tomcat group
directory '/usr/local/etc/sophos/event_svc' do
  owner TOMCAT_USER
  group TOMCAT_GROUP
  mode '0770'
  action :create
end

directory '/usr/local/etc/sophos/seclogging_svc' do
  owner TOMCAT_USER
  group TOMCAT_GROUP
  mode '0770'
  action :create
end

# Set file owner to tomcat user and group
file '/usr/local/etc/sophos/event_svc/authentication.properties' do
  owner TOMCAT_USER
  group TOMCAT_GROUP
  mode '0664'
  action :create
end

file '/usr/local/etc/sophos/seclogging_svc/authentication.properties' do
  owner TOMCAT_USER
  group TOMCAT_GROUP
  mode '0664'
  action :create
end