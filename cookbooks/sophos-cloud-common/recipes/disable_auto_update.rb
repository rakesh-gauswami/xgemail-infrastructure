#
# Cookbook Name:: sophos-cloud-common
# Recipe:: disable_auto_update
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Turn off auto-update for ALL packages.
cookbook_file "90-repo-upgrade-none.cfg" do
  path "/etc/cloud/cloud.cfg.d/90-repo-upgrade-none.cfg"
  source "90-repo-upgrade-none.cfg"
  mode "0600"
  owner "root"
  group "root"
end
