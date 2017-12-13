#
# Cookbook Name:: sophos-cloud-elasticsearch
# Recipe:: 0-defines
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute

$SYSWIDE_INSTEMP_DIR = node['sophos_cloud']['tmp_directory']
$SYSWIDE_ACCOUNT_NAM = node['sophos_cloud']['account'] || 'inf'
$SYSWIDE_ETCDFLT_DIR = '/etc/sysconfig'

# ----------------------------------------
# S_x: Service X
# U_x: Utility X

# ----------------------------------------
$S_ESRCH = 'elasticsearch'
$S_ESRCH_PRODUCT_DIR = "/usr/share/elasticsearch"
$S_ESRCH_MAINCFG_DIR = "/etc/elasticsearch"

$S_ESRCH_LOGFILE_DIR = '/var/log/elasticsearch'
$S_ESRCH_WORKDIR_DIR = '/var/lib/elasticsearch'

# FIXME-algo: CF Templates have to define these; the settings below
# should kick in in my early manual tests only
$S_ESRCH_BIGDATA_DIR = node['elasticsearch']['data_dir'] || '/storage'
$S_ESRCH_HEAPMAX_PCT = node['elasticsearch']['heap_percentage'] || '50'

$S_ESRCH_AUX_DIR = '/opt/sophos/elasticsearch'
