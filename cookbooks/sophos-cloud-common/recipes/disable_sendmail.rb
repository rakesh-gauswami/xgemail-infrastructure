#
# Cookbook Name:: sophos-cloud-common
# Recipe:: disable_sendmail
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

service "sendmail" do
  action [:stop]
end

bash "disable_sendmail_on_boot" do
  user "root"
  code "chkconfig sendmail off"
end
