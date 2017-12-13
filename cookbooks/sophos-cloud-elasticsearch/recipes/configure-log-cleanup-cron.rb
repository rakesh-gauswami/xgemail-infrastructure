# coding: utf-8
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# ----------------------------------------
include_recipe 'sophos-cloud-elasticsearch::0-defines'
# ----------------------------------------

CRON_JOB_TIMEOUT = node['elasticsearch']['cron_job_timeout']
raise "Undefined CRON_JOB_TIMEOUT" if CRON_JOB_TIMEOUT.nil?

LOG_RETENTION_DAYS = node['elasticsearch']['log_retention_days']
raise "Undefined LOG_RETENTION_DAYS" if LOG_RETENTION_DAYS.nil?

CRON_NAME = 'elasticsearch-log-cleanup-cron'

PACKAGE_DIR = "#{$S_ESRCH_AUX_DIR}/#{CRON_NAME}"
CRON_SCRIPT = "#{CRON_NAME}.sh"
CRON_SCRIPT_PATH = "#{PACKAGE_DIR}/#{CRON_SCRIPT}"

directory PACKAGE_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

template CRON_SCRIPT_PATH do
  source CRON_SCRIPT
  mode '0750'
  owner 'root'
  group 'root'
  variables(
    :elasticsearch_log_dir => $S_ESRCH_LOGFILE_DIR,
    :elasticsearch_log_retention_days => LOG_RETENTION_DAYS
  )
end

CRON_COMMAND =
  'source /etc/profile && ' +
    "timeout '#{CRON_JOB_TIMEOUT}'" +
    "flock --nb /var/lock/#{CRON_SCRIPT}.lock " +
    "-c '#{CRON_SCRIPT_PATH}'" +
  '>/dev/null 2>&1'

cron CRON_NAME do
  hour '3'
  minute '6'
  user 'root'
  command CRON_COMMAND
end
