#
# Cookbook Name:: sophos-cloud-common
# Recipe:: test-helper
#
# Copyright 2017 Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group.
# All other product and company names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This recipe tests functionality defined win sophos-cloud-common_helper
#

# Include Helper libraries

::Chef::Recipe.send(
  :include,
  ::SophosCloud::CommonHelper
)
::Chef::Resource.send(
  :include,
  ::SophosCloud::CommonHelper
)

Chef::Log.info("common_account = <#{common_account}>")
Chef::Log.info("common_application_name = <#{common_application_name}>")
Chef::Log.info("common_cookbook_install_dir = <#{common_cookbook_install_dir}>")
Chef::Log.info("common_cookbook_log_dir = <#{common_cookbook_log_dir}>")
Chef::Log.info("common_cookbook_version = <#{common_cookbook_version}>")
Chef::Log.info("common_dns_name = <#{common_dns_name('foo')}>")
Chef::Log.info("common_docker_registry = <#{common_docker_registry}>")
Chef::Log.info("common_install_dir = <#{common_install_dir}>")
Chef::Log.info("common_instance_id = <#{common_instance_id}>")
Chef::Log.info("common_log_dir = <#{common_log_dir}>")
Chef::Log.info("common_region = <#{common_region}>")
Chef::Log.info("common_s3_bucket_region = <#{common_s3_bucket_region}>")
Chef::Log.info("common_thirdparty_bucket = <#{common_thirdparty_bucket}>")
Chef::Log.info("common_thirdparty_bucket_leading_dir = <#{common_thirdparty_bucket_leading_dir}>")
Chef::Log.info("common_vpc_name = <#{common_vpc_name}>")

log 'common_account' do
  message "log common_account = <#{common_account}>"
end
log 'common_application_name' do
  message "log common_application_name = <#{common_application_name}>"
end
log 'common_cookbook_install_dir' do
  message "log common_cookbook_install_dir = <#{common_cookbook_install_dir}>"
end
log 'common_cookbook_log_dir' do
  message "log common_cookbook_log_dir = <#{common_cookbook_log_dir}>"
end
log 'common_cookbook_version' do
  message "log common_cookbook_version = <#{common_cookbook_version}>"
end
log 'common_dns_name' do
  message "log common_dns_name = <#{common_dns_name('foo')}>"
end
log 'common_docker_registry' do
  message "log common_docker_registry = <#{common_docker_registry}>"
end
log 'common_install_dir' do
  message "log common_install_dir = <#{common_install_dir}>"
end
log 'common_instance_id' do
  message "log common_instance_id = <#{common_instance_id}>"
end
log 'common_log_dir' do
  message "log common_log_dir = <#{common_log_dir}>"
end
log 'common_region' do
  message "log common_region = <#{common_region}>"
end
log 'common_s3_bucket_region' do
  message "log common_s3_bucket_region = <#{common_s3_bucket_region}>"
end
log 'common_thirdparty_bucket' do
  message "log common_thirdparty_bucket = <#{common_thirdparty_bucket}>"
end
log 'common_thirdparty_bucket_leading_dir' do
  message "log common_thirdparty_bucket_leading_dir = <#{common_thirdparty_bucket_leading_dir}>"
end
log 'common_vpc_name' do
  message "log common_vpc_name = <#{common_vpc_name}>"
end
