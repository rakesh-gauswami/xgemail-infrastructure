# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: run_install_cleanup
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#

# TODO discuss removing all of the cookbooks in /var/chef/chef-repo - security vs. debug-ability
# /var/chef/chef-repo/*.enc
# /var/chef/chef-repo/*.tar.gz
# /var/chef/chef-repo/cookbooks*
# /var/chef/chef-repo/data_bags
# /var/chef/chef-repo/environments
# /var/chef/chef-repo/roles

# TODO revisit /var/sophos/*

FILES_TO_REMOVE = %w[
  /tmp/*.enc
  /tmp/*.log
  /tmp/*.sh
  /tmp/*.war
  /tmp/chef*
  /tmp/META-INF
  /tmp/sophos
  /var/chef/chef-repo/.chef/*
  /var/log/sophos/*
]

# Using the file resource took over 4 minutes to delete ~50 files.
# It doesn't handle wildcards well, so using bash instead.
FILES_TO_REMOVE.each do |file|
  bash "rm -rf files" do
    user "root"
    code "rm -rf #{file}"
  end
end
