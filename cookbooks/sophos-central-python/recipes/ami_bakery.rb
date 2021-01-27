#
# Cookbook Name:: sophos-central-python
# Recipe:: ami_bakery
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

PACKAGE = "ami_bakery"

bash "install #{PACKAGE} package" do
  cwd "/var/chef/chef-repo/cookbooks/sophos-central-python/files/default"
  code "./install_package.py #{PACKAGE}"
  user "root"
end

bash "enable #{PACKAGE} service startup after reboot" do
  user "root"
  code "chkconfig --add #{PACKAGE}"
end

bash "modprobe ip_tables" do
  user "root"
  code "modprobe ip_tables"
end

bash "start #{PACKAGE} service now" do
  user "root"
  code "service #{PACKAGE} start"
end

# TODO ;;; Configure log rotation
# TODO ;;; Configure logstash??? that's a separate recipe, isn't it?
