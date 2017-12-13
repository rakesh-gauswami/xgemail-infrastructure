# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute

# ----------------------------------------
include_recipe 'sophos-cloud-elasticsearch::0-defines'
# ----------------------------------------

services_to_stop = %w(elasticsearch)
services_to_stop.each do |srv|
  service srv do
    action [:disable, :stop]
  end
end

[ '/sbin/sysctl -q -w vm.swappiness=1' ].each do |cmd|
  bash cmd do
    user 'root'
    code cmd
  end
end

# $S_ESRCH_MAINCFG_DIR will be created by the RPM install
dirs_to_create = [ $S_ESRCH_LOGFILE_DIR,
                   $S_ESRCH_WORKDIR_DIR,
                   $S_ESRCH_BIGDATA_DIR ]
dirs_to_create.each do |dir|
  directory dir do
    mode '0755'
    owner 'elasticsearch'
    group 'elasticsearch'
    action :create
    recursive true
  end
end

# ----------------------------------------
## I am using 2048M as an absolute fail-safe default

# (31 * 1024 = 31744) See Elasticsearch documentation for why this is a reasonable maximum
# Using "node[:memory][:total]" would be elegant but require a harder processing, considering the units in which the result may be presented
es_heap_size = `free -m | awk '/^Mem:/{ x = int($2 * #{$S_ESRCH_HEAPMAX_PCT} / 100); printf("%dm", (x > 0 ? (x <= 31744 ? x : 31744) : 2048)); exit 0; }' || "2048m"`
## We might want not reserve that much memory on a "client-only" node
## but whom else would it be granted to there?

template "#{$SYSWIDE_ETCDFLT_DIR}/elasticsearch" do
  source 'etc-sysconfig-elasticsearch.conf'
  variables ({ :es_heap_size => es_heap_size,
               :log_dir => $S_ESRCH_LOGFILE_DIR,
               :wrk_dir => $S_ESRCH_WORKDIR_DIR,
               :dat_dir => $S_ESRCH_BIGDATA_DIR })
  mode '0644'
  owner 'root'
  group 'root'
end

template "#{$S_ESRCH_MAINCFG_DIR}/elasticsearch.yml" do
  source 'etc-elasticsearch-elasticsearch.yml.conf'
  variables ({ 
               :discovery_ec2_tag_key => node['elasticsearch']['discovery_ec2_tag_key'],
               :discovery_ec2_tag_val => node['elasticsearch']['discovery_ec2_tag_val'],
               :cluster_name => node['elasticsearch']['clustername'],
               :node_client => node['elasticsearch']['is_client_node'],
               :node_data => node['elasticsearch']['is_data_node'],
               :node_master => node['elasticsearch']['is_master_node'],
               :aws_region => node['sophos_cloud']['region'],
               :minimum_master_nodes_quorum => node['elasticsearch']['minimum_master_nodes_quorum'],
               :node_name => "hydra-esn-#{node['sophos_cloud']['instance_id']}" })
  mode '0644'
  owner 'root'
  group 'root'
end

directory "#{$S_ESRCH_BIGDATA_DIR}" do
    mode '0755'
    owner 'elasticsearch'
    group 'elasticsearch'
    action :create
    recursive true
end

execute 'chown elasticsearch storage directory' do
    command "chown -R elasticsearch:elasticsearch #{$S_ESRCH_BIGDATA_DIR}"
  end

# ----------------------------------------
services_to_start = %w(elasticsearch)
services_to_start.each do |srv|
  service srv do
    action [:enable, :start]
  end
end
