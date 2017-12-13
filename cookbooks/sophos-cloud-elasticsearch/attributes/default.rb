#
# Cookbook Name:: sophos-cloud-elasticsearch
# Attribute:: default
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# The value of #{node[k1][k2]} will come from two places:
#
#   (1) (if exists) a proper setting taken from the 'attributes.json'
#       file residing in 'script_dir' (see below).
#
#   (2) (if (1) does not exist) the value, for the same keys 'k0' and
#       'k1', taken from the three-dimensional map 'default'
#
# The following populates the 'default' map.  Do not put in anything
# here that cannot be a reasonable default for all systems where these
# cookbooks are running; e.g. do not add a "real" account name.

# In the below, 'CFT' stands for "Cloud Formation template".

# Setting 'UNDEF' to 'nil' is important for '0-recipe-defs.rb'
UNDEF = nil

# Sophos-general settings
default['sophos_cloud']['tmp_directory'] = '/tmp/sophos'
default['sophos_cloud']['script_dir'] = '/var/sophos/scripts'

default['sophos_cloud']['region'] = UNDEF
default['sophos_cloud']['account'] = UNDEF

# Elasticsearch-specific things

## There is no reason to specify these version in CFT as we eliminate
## 99% of the flexibility by having only approximately one version of
## either in the S3 buckets we will be pulling these from.
default['elasticsearch']['elasticsearch_version'] = '1.7.5'
default['elasticsearch']['ec2_discovery_version'] = '2.7.1'

## For these two there may be hardcoded defaults in the cookbook code,
## for temporary testing purposes only. CFT should specify them.
default['elasticsearch']['heap_percentage'] = UNDEF
default['elasticsearch']['data_dir'] = UNDEF

## There can be no default for these; CFT must specify them all.
default['elasticsearch']['clustername'] = UNDEF
default['elasticsearch']['discovery_ec2_tag_key'] = UNDEF
default['elasticsearch']['discovery_ec2_tag_val'] = UNDEF

default['elasticsearch']['is_client_node'] = UNDEF
default['elasticsearch']['is_data_node'] = UNDEF
default['elasticsearch']['is_master_node'] = UNDEF

default['elasticsearch']['minimum_master_nodes_quorum'] = UNDEF

default['elasticsearch']['cron_job_timeout'] = '10m'
default['elasticsearch']['log_retention_days'] = 7
