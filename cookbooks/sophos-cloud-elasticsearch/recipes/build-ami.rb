# coding: utf-8
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# ----------------------------------------
include_recipe 'sophos-cloud-elasticsearch::0-defines'
# ----------------------------------------

shcmd_h = Mixlib::ShellOut.new('echo -n $(runlevel 2>&1)')
runlevel = shcmd_h.run_command.stdout

MANUAL_TEST_RUN = ($SYSWIDE_ACCOUNT_NAM != 'hmr-core')
log "runlevel='#{runlevel}', $SYSWIDE_ACCOUNT_NAM=#{$SYSWIDE_ACCOUNT_NAM}, MANUAL_TEST_RUN=#{MANUAL_TEST_RUN}" do level :info end

if MANUAL_TEST_RUN
  services_to_stop = %w(elasticsearch)
  services_to_stop.each do |srv|
    service srv do
      action [:disable, :stop]
    end
  end
end

dirs_to_create = [ $SYSWIDE_INSTEMP_DIR,
                   $S_ESRCH_PRODUCT_DIR ]
dirs_to_create.each do |dir|
  directory dir do
    mode '0755'
    owner 'root'
    group 'root'
    action :create
    recursive true
  end
end

# ------------------------------------------------------------

elasticsearch_version = node['elasticsearch']['elasticsearch_version']
ec2_discovery_version = node['elasticsearch']['ec2_discovery_version']

# ----------------------------------------
# FIXME-algo: in the future, for general needs, the stuff may be
#  stored in a folder different than xgemail
def file_s3_uri(file_bn, manual_test_run)
  mp = manual_test_run ? $SYSWIDE_ACCOUNT_NAM : 'applications'
  return "s3://cloud-#{mp}-3rdparty/xgemail/#{file_bn}"
end

def file_fetch_cmd(file_bn, manual_test_run)
  file_uri = file_s3_uri(file_bn, manual_test_run)
  file_fdp = "#{$SYSWIDE_INSTEMP_DIR}/#{file_bn}"
  return "[ -f #{file_fdp} ] || aws --region us-west-2 s3 cp #{file_uri} #{file_fdp}"
end

def file_deinstall_cmd_rpm(rpm_name, manual_test_run)
  return "#{manual_test_run ? '' : ': '}yum remove -ty #{rpm_name}"
end

def file_deinstall_cmd_plg(plg_name, manual_test_run)
  return "#{manual_test_run ? '' : ': '}bin/plugin -r #{plg_name} || true"
end

def file_install_cmd_rpm(rpm_file, manual_test_run)
  return "yum install -ty #{$SYSWIDE_INSTEMP_DIR}/#{rpm_file}"
end

def file_install_cmd_plg(plg_subdir, plg_file, manual_test_run)
  return "cd #{$S_ESRCH_PRODUCT_DIR} && mkdir -p plugins/#{plg_subdir} && unzip -o #{$SYSWIDE_INSTEMP_DIR}/#{plg_file} -d plugins/#{plg_subdir}"
end

# ------------------------------------------------------------

# I prefer this to a HEREDOC because of a better logging this way
[ 'aws configure set default.s3.signature_version s3v4' ].each do |cmd|
  bash cmd do
    user 'root'
    code cmd
  end
end

{ 'elasticsearch' => "elasticsearch-#{elasticsearch_version}.noarch.rpm" }.each do |rpm_name, rpm_file|
  [ file_deinstall_cmd_rpm(rpm_name, MANUAL_TEST_RUN),
    file_fetch_cmd(rpm_file, MANUAL_TEST_RUN),
    file_install_cmd_rpm(rpm_file, MANUAL_TEST_RUN) ].each do |cmd|
    bash cmd do
      cwd $SYSWIDE_INSTEMP_DIR
      user 'root'
      code cmd
    end
  end
end

[ '[ -d plugins ] || mkdir plugins' ].each do |cmd|
  bash cmd do
    cwd $S_ESRCH_PRODUCT_DIR
    user 'root'
    code cmd
  end
end

# The way to get stuff in for uploading it in the cloud next:
# http://download.elasticsearch.org/elasticsearch/elasticsearch-cloud-aws/elasticsearch-cloud-aws-2.7.1.zip
# 'mobz/elasticsearch-head' => 'https://github.com/mobz/elasticsearch-head/archive/master.zip' ## https://github.com/mobz/elasticsearch-head/archive/master.zip 'head'
# 'lukas-vlcek/bigdesk' => 'https://github.com/lukas-vlcek/bigdesk/archive/master.zip' 'bigdesk'
# 'lmenezes/elasticsearch-kopf' => 'https://github.com/lmenezes/elasticsearch-kopf/archive/master.zip' 'kopf'
# 'royrusso/elasticsearch-HQ' => https://github.com/royrusso/elasticsearch-HQ/archive/master.zip 'HQ'

# FIXME-algo: I have found that the mechanics of matching the plugin version with the one of the server is tricky
#   and to do it right, I'll need to think; i.e. not doing it for now.
[
  # [ P-NAME, P-SUBDIR, P-FILEBASENAME ]
  [ 'cloud-aws', 'cloud-aws', "elasticsearch-cloud-aws-#{ec2_discovery_version}.zip" ]
].each do |plg_desc|
  plg_name = plg_desc[0]
  plg_sdir = plg_desc[1]
  plg_file = plg_desc[2]
  [ file_deinstall_cmd_plg(plg_name, MANUAL_TEST_RUN),
    file_fetch_cmd(plg_file, MANUAL_TEST_RUN),
    file_install_cmd_plg(plg_sdir, plg_file, MANUAL_TEST_RUN) ].each do |cmd|
    bash cmd do
      cwd $S_ESRCH_PRODUCT_DIR
      user 'root'
      code cmd
    end
  end
end

# Install packages for all supported file systems.

yum_package "xfsprogs" do
  action :install
end

include_recipe 'sophos-cloud-elasticsearch::configure-log-cleanup-cron'
