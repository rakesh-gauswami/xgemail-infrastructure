#
# Cookbook Name:: sophos-cloud-common
# Recipe:: configure_auditd
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

file "audit.rules.default" do
  path "/etc/audit/rules.d/audit.rules.default"
  action :delete
end

template "auditd configuration file" do
  path "/etc/audit/auditd.conf"
  source "etc-audit-auditd.conf.erb"
  mode "0640"
  owner "root"
  group "root"
end

template "auditd rules file" do
  path "/etc/audit/audit.rules"
  source "etc-audit-audit.rules.erb"
  mode "0640"
  owner "root"
  group "root"
  variables(
    # Pass list of files with setuid or setgid bits set.
    :paths => %x[/bin/find / -xdev \\( -perm -4000 -o -perm -2000 \\) -type f].split
  )
end

ruby_block "enable auditing for processes that start prior to auditd" do
  block do
    sed = Chef::Util::FileEdit.new("/etc/default/grub")
    sed.search_file_replace(/^kernel (?!.* audit=1\b).*\S/, "\\0 audit=1")
    sed.write_file
  end
end
