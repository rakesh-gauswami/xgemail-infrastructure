#
# Cookbook Name:: sophos-cloud-tomcat
# Recipe:: update
# (1) LogBack Severity Level:
#     - creates a backup of logback.xml
#     - updates log logging severity level
#     - A value of default restores the original logback severity level
#     - Restarts tomcat in case of a correct severity level or "default"
#       - this is currently necessary:
#           (a) because of using LogBack
#           (b) no watchdog implementation in webapp code
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# Update Tomcat options

log_file_name = "#{node['tomcat']['webapp_dir']}/#{node['sophos_cloud']['war_name']}/WEB-INF/conf/#{node['tomcat']['logging_conf_filename']}"
log_file_name_backup = "#{node['tomcat']['webapp_dir']}/#{node['sophos_cloud']['war_name']}/WEB-INF/conf/#{node['tomcat']['logging_conf_filename']}.backup"

mongos_net_port = node["mongo"]["mongos_net_port"]

# CGOLD-646 apogrebnyak : default to 'skip' level always
severity_level = 'skip'

log "Unknown severity level specified: #{severity_level}" do
  level :info
  only_if { severity_level == "unknown" }
end

return if severity_level == "unknown"

log "Skip severity level update..." do
  level :info
  only_if { severity_level == "skip" }
end

if severity_level != "skip"

  log "Open log file: #{log_file_name}" do
    level :info
  end

  log "Change to severity level: #{severity_level}" do
    level :info
  end

  log "Backup log defaults: #{log_file_name} to #{log_file_name_backup}" do
    level :info
    not_if { ::File.exists?("#{log_file_name_backup}") }
  end

  webapp_conf_dir = "#{node['tomcat']['webapp_dir']}/#{node['sophos_cloud']['war_name']}/WEB-INF/conf"

  ruby_block "Wait until webapp dir created" do
    block do
      true until ::File.exists?("#{webapp_conf_dir}")
    end
  end

  bash "Backup log defaults" do
    user "root"
    cwd "/tmp"
    code <<-EOH
    cp -f #{log_file_name} -T #{log_file_name_backup}
    EOH
    not_if { ::File.exists?("#{log_file_name_backup}") }
    only_if { ::File.exists?("#{log_file_name}") }
  end

  ruby_block "Change logging severity level" do
    block do
      sed = Chef::Util::FileEdit.new(log_file_name)
      sed.search_file_replace(/level="[a-z]+"/, "level=\"#{severity_level}\"")
      sed.write_file
    end
    only_if { severity_level != "default"}
    only_if { ::File.exists?("#{log_file_name}") }
  end

  bash "Restore log defaults" do
    user "root"
    cwd "/tmp"
    code <<-EOH
          cp -f #{log_file_name_backup} -T #{log_file_name}
    EOH
    only_if { ::File.exists?("#{log_file_name_backup}") }
    only_if { severity_level == "default" }
  end


  bash "Stop Tomcat" do
    user "root"
    cwd "/tmp"
    code <<-EOH
      #{node['tomcat']['stop_command']}
    EOH
  end

  bash "Start Tomcat" do
    user "root"
    cwd "/tmp"
    code <<-EOH
      #{node['tomcat']['start_command']}
    EOH
  end

end

bootstrap_file = node['tomcat']['sophos_dir'] + "/bootstrap.properties"
application_file = node['tomcat']['sophos_dir'] + "/application.properties"

ruby_block "Replace mongodb with mongos in bootstrap properties" do
  block do
    # Bootstrap Properties
    btp = Chef::Util::FileEdit.new(bootstrap_file)
    btp.search_file_replace_line(
        "mongoClient.addresses *= *.*",
        "mongoClient.addresses = 127.0.0.1:#{mongos_net_port}")
    btp.write_file

    # Application Properties
    app = Chef::Util::FileEdit.new(application_file)
    app.search_file_replace_line(
        "mongoDb.cfg.addresses *= *.*",
        "mongoDb.cfg.addresses = 127.0.0.1:#{mongos_net_port}")
    app.write_file
  end
  only_if { node["sophos_cloud"]["sharding_enabled"] == "true" }
end
