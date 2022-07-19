#
# Cookbook Name:: sophos-cloud-common
# Attribute:: default
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Sophos-Cloud
default['sophos_cloud']['instance_id']      = `curl -s -S http://169.254.169.254/latest/meta-data/instance-id`
default['sophos_cloud']['region']           = `curl -s -S http://169.254.169.254/latest/meta-data/placement/availability-zone`.sub(/[a-z]$/, '')
default['sophos_cloud']['tmp']              = '/tmp/sophos'
default['sophos_cloud']['local_cert_path']  = '/etc/ssl/certs'
default['sophos_cloud']['local_key_path']   = '/etc/ssl/private'
default['sophos_cloud']['logzio_poc']       = 'False'
default['sophos_cloud']['s3_bucket_region'] = 'us-west-2'
default['sophos_cloud']['thirdparty']       = '//central-3rdparty'

# Sophos-Cloud-Common (Want to Start Using the Format: default['cookbook']['recipe']['variable_name'])
# Install Logstash Forwarder
default['sophos_cloud_common']['install_logstash_forwarder']['repository_version'] = "1.5"
default['sophos_cloud_common']['hosted_zone_suffix'] = 'hydra.sophos.com'

# Configure Logstash Forwarder

default['sophos_cloud_common']['configure_logstash_forwarder']['mail_logs'] = 'False'
default['sophos_cloud_common']['configure_logstash_forwarder']['nginx_logs'] = 'False'
default['sophos_cloud_common']['configure_logstash_forwarder']['custom_logs'] = 'False'
default['sophos_cloud_common']['configure_logstash_forwarder']['logstash_timeout'] = 10
default['sophos_cloud_common']['configure_logstash_forwarder']['instance_log_path'] = '/data/log/*'
default['sophos_cloud_common']['configure_logstash_forwarder']['instance_log_type'] = 'applog'
default['sophos_cloud_common']['configure_logstash_forwarder']['should_use_default_logstash_vpc_name'] = false
default['sophos_cloud_common']['configure_logstash_forwarder']['sophos_logs'] = 'False'
default['sophos_cloud_common']['configure_logstash_forwarder']['sophos_log_path'] = '/data/log/*'
default['sophos_cloud_common']['configure_logstash_forwarder']['sophos_log_type'] = 'applog'

default['sophos_cloud_common']['remote_user'] = 'remote_user'

default['sophos_cloud_common']['docker_registry'] = 'artifactory.sophos-tools.com'
default['sophos_cloud_common']['install_dir'] = '/opt/sophos'
default['sophos_cloud_common']['log_dir'] = '/var/log/sophos'
