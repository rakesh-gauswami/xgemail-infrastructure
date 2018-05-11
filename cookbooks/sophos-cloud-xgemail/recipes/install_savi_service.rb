#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_savi_service
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure SAVi service for XGEMAIL

# Ensure all required packages are installed before proceeding
# with SAVi installation
NODE_TYPE = node['sophos_cloud']['cluster']
if NODE_TYPE == 'mailoutbound' || NODE_TYPE == 'mailinbound'
  package 'wget'
  package 'unzip'
  package 'python'
  package 'tar'

  CRON_MINUTE_FREQUENCY = node['xgemail']['savdid_ide_cron_minute_frequency']
  CRON_JOB_TIMEOUT_IDE  = node['xgemail']['cron_job_timeout']
  CRON_JOB_TIMEOUT_VDL  = node['xgemail']['savdid_cron_job_timeout_vdl']
  PACKAGE_DIR           = node['xgemail']['savdid_dir']

  CRON_SCRIPT_IDE = 'savdid-ide-sync.sh'
  CRON_SCRIPT_VDL = 'savdid-vdl-sync.sh'

  CRON_SCRIPT_IDE_PATH = "#{PACKAGE_DIR}/#{CRON_SCRIPT_IDE}"
  CRON_SCRIPT_VDL_PATH = "#{PACKAGE_DIR}/#{CRON_SCRIPT_VDL}"

  # Create user for SAVI content filter handling
  user 'filter' do
    system true
    shell '/bin/false'
  end

  directory "#{node['xgemail']['savdid_log_xgemail_dir']}" do
    owner 'filter'
    group 'filter'
    mode '0755'
    action :create
    recursive true
  end

  directory "#{node['xgemail']['savdid_dir']}" do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  directory "#{node['xgemail']['savdid_log_dir']}" do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  cookbook_file "#{node['xgemail']['savdid_dir']}/sav-download.py" do
    source 'sav-download.py'
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end

  # Extract files
  execute 'extract_savi_library_files' do
    user 'root'
    cwd '/opt/sophos/packages'
    command <<-EOH
      tar xf #{node['xgemail']['savdid_library']}-#{node['xgemail']['savdid_savi_version']}.tar.gz \
	-C #{node['xgemail']['savdid_dir']}
    EOH
  end

  # Cleanup old IDE files
  execute 'cleanup_savi_ide_files' do
    user 'root'
    cwd '/tmp'
    command <<-EOH
      find "#{node['xgemail']['savdid_dir']}" -type f -name "ide_*" | sort | head -n -1 | xargs -r rm
    EOH
  end

  execute CRON_SCRIPT_VDL_PATH do
    user "root"
    action :nothing
  end

  execute CRON_SCRIPT_IDE_PATH do
    user "root"
    action :nothing
  end

  template 'create synchronization script for VDL' do
    path "#{node['xgemail']['savdid_dir']}/savdid-vdl-sync.sh"
    source 'savdid-vdl-sync.erb'
    mode '0700'
    owner 'root'
    group 'root'
    variables(
            :SOPHOSAV_PKG_SAV_TMP_DIR => node['xgemail']['savdid_dir'],
            :SOPHOSAV_PKG_USERNAME => node['xgemail']['savdid_username'],
            :SOPHOSAV_PKG_PASSWORD => node['xgemail']['savdid_password'],
            :SOPHOSAV_PKG_LOCAL_DIR => node['xgemail']['savdid_sig_dir'],
            :SOPHOSAV_SERVICE_NAME => node['xgemail']['savdid_service_name']
    )
    notifies :run, "execute[#{CRON_SCRIPT_VDL_PATH}]", :immediately
  end

  template 'create synchronization script for IDE' do
    path "#{node['xgemail']['savdid_dir']}/savdid-ide-sync.sh"
    source 'savdid-ide-sync.erb'
    mode '0700'
    owner 'root'
    group 'root'
    variables(
            :SOPHOSAV_PKG_SAV_TMP_DIR => node['xgemail']['savdid_dir'],
            :SOPHOSAV_PKG_USERNAME => node['xgemail']['savdid_username'],
            :SOPHOSAV_PKG_PASSWORD => node['xgemail']['savdid_password'],
            :SOPHOSAV_PKG_LOCAL_DIR => node['xgemail']['savdid_sig_dir'],
            :SOPHOSAV_SERVICE_NAME => node['xgemail']['savdid_service_name']
    )
    notifies :run, "execute[#{CRON_SCRIPT_IDE_PATH}]", :immediately
  end

  execute 'extract_vdl_ide_files' do
      user 'root'
      cwd "#{node['xgemail']['savdid_dir']}"
      command <<-EOH
        unzip -o vdl.zip -d #{node['xgemail']['savdid_dir']}/sav-install
        unzip -o ide_*.zip -d #{node['xgemail']['savdid_sig_dir']}
      EOH
  end

  execute 'extract_savdi_library_files' do
    user 'root'
    cwd '/opt/sophos/packages'
    command <<-EOH
      tar xf #{node['xgemail']['savdid_savdi_library']}-#{node['xgemail']['savdid_version']}.tar.gz \
	-C #{node['xgemail']['savdid_dir']}
    EOH
  end

  # Run installation
  execute 'install_savi' do
    command "sh #{node['xgemail']['savdid_dir']}/sav-install/install.sh"
  end

  execute 'install savdi' do
    command "sh #{node['xgemail']['savdid_dir']}/savdi-install/savdi_install.sh"
  end

  template 'create savdid service file' do
    path "/etc/init.d/#{node['xgemail']['savdid_service_name']}"
    source 'savdid.service.erb'
    mode '0744'
    owner 'root'
    group 'root'
    variables(
            :savdid_service_name => node['xgemail']['savdid_service_name'],
            :savdid_dir => node['xgemail']['savdid_dir']
    )
  end

  # Read the SXL dns Ip from name server config file
  sxl_dns_ip_res = ''
  IO.readlines(node['xgemail']['savdid_sxl_dns_res']).each do |line|
    tokens = line.split(' ')
    if (tokens[0]).casecmp('nameserver') == 0
      sxl_dns_ip_res = tokens[1]
      break
    end
  end

  template 'create savdid config file' do
    path "#{node['xgemail']['savdid_dir']}/savdid.conf"
    source 'savdid.conf.erb'
    mode '0640'
    owner 'root'
    group 'root'
    variables(
            :savdid_cxmail_version => node['xgemail']['savdid_cxmail_version'],
            :savdid_group => node['xgemail']['savdid_group'],
            :savdid_log_dir => node['xgemail']['savdid_log_dir'],
            :savdid_max_memory_size_in_bytes => node['xgemail']['savdid_max_memory_size_in_bytes'],
            :savdid_max_request_time_in_sec => node['xgemail']['savdid_max_request_time_in_sec'],
            :savdid_max_scan_data_size_in_bytes => node['xgemail']['savdid_max_scan_data_size_in_bytes'],
            :savdid_max_scan_time_in_sec => node['xgemail']['savdid_max_scan_time_in_sec'],
            :savdid_owner => node['xgemail']['savdid_owner'],
            :savdid_pid_file => node['xgemail']['savdid_pid_file'],
            :savdid_receive_timeout_in_sec => node['xgemail']['savdid_receive_timeout_in_sec'],
            :savdid_send_timeout_in_sec => node['xgemail']['savdid_send_timeout_in_sec'],
            :savdid_sxl_dns_ip => sxl_dns_ip_res,
            :savdid_sxl_hex_id_customer => node['xgemail']['savdid_sxl_hex_id_customer'],
            :savdid_sxl_hex_id_machine => node['xgemail']['savdid_sxl_hex_id_machine'],
            :savdid_sxl_live_protection_enabled => node['xgemail']['savdid_sxl_live_protection_enabled'],
            :savdid_sxl_pua_detection => node['xgemail']['savdid_sxl_pua_detection'],
            :savdid_sxl_server_list => node['xgemail']['savdid_sxl_server_list'],
            :savdid_sxl_top_level_domain => node['xgemail']['savdid_sxl_top_level_domain']
    )
  end

  execute 'copy_savdid_executable' do
    command "cp -f #{node['xgemail']['savdid_dir']}/savdi-install/savdid /usr/sbin/#{node['xgemail']['savdid_service_name']}"
  end

  execute 'run SAVi on startup' do
    command 'chkconfig savdid on'
  end

  # Syncronize the SAVi VDL signatures
  cron CRON_SCRIPT_VDL_PATH do
    minute '0'
    hour '0'
    user 'root'
    command "timeout #{CRON_JOB_TIMEOUT_VDL}" +
            " flock --nb /var/lock/#{CRON_SCRIPT_VDL} -c '#{CRON_SCRIPT_VDL_PATH}'" +
            " &>> #{node['xgemail']['savdid_log_dir']}/vdl-sync.log"
  end

  # Syncronize the SAVi IDE signatures
  cron CRON_SCRIPT_IDE_PATH do
    minute "*/#{CRON_MINUTE_FREQUENCY}"
    user 'root'
    command "timeout #{CRON_JOB_TIMEOUT_IDE}" +
            " flock --nb /var/lock/#{CRON_SCRIPT_IDE} -c '#{CRON_SCRIPT_IDE_PATH}'" +
            " &>> #{node['xgemail']['savdid_log_dir']}/ide-sync.log"
  end

  # Cleanup
  directory "#{node['xgemail']['savdid_dir']}/sav-install" do
    recursive true
    action :delete
  end

  directory "#{node['xgemail']['savdid_dir']}/savdi-install" do
    recursive true
    action :delete
  end

  service "#{node['xgemail']['savdid_service_name']}" do
    action :restart
  end

else

  log "Skipped SAVi installation for non-mail instance #{node['sophos_cloud']['cluster']}." do
    level :info
  end

end
