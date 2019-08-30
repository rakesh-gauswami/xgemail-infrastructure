#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: install_jilter_inbound
#
# Copyright 2019, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Configure Xgemail Jilter service for inbound email processing
#

PACKAGES_DIR = '/jilter'
LIBSPF_PACKAGES_DIR = '/opt/sophos/packages'
DEPLOYMENT_DIR = '/opt/sophos/xgemail'
NODE_TYPE = node['xgemail']['cluster_type']
DIRECTION = node['xgemail']['direction']
JILTER_VERSION = node['xgemail']['jilter_version']
JILTER_PACKAGE_NAME = "xgemail-jilter-#{DIRECTION}-#{JILTER_VERSION}"

directory PACKAGES_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

directory DEPLOYMENT_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

if NODE_TYPE == 'jilter-inbound'
  execute 'extract_jilter_package' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      tar xf #{JILTER_PACKAGE_NAME}.tar -C #{DEPLOYMENT_DIR}
      mv #{DEPLOYMENT_DIR}/xgemail-jilter-#{DIRECTION}*SNAPSHOT #{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}
  EOH
  end

else
  if NODE_TYPE == 'jilter-outbound'
  execute 'extract_jilter_package' do
  user 'root'
  cwd "#{PACKAGES_DIR}"
  command <<-EOH
      tar xf #{JILTER_PACKAGE_NAME}.tar -C #{DEPLOYMENT_DIR}
      mv #{DEPLOYMENT_DIR}/xgemail-jilter-#{DIRECTION}*SNAPSHOT #{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}
      tar xf inbound/xgemail-jilter-inbound-#{JILTER_VERSION}.tar -C #{DEPLOYMENT_DIR}
      mv #{DEPLOYMENT_DIR}/xgemail-jilter-inbound* #{DEPLOYMENT_DIR}/xgemail-jilter-inbound
  EOH
  end

  template "launch_darkly_sandbox.properties" do
    path "#{DEPLOYMENT_DIR}/xgemail-jilter-#{DIRECTION}/conf/launch_darkly_sandbox.properties"
    source 'jilter-launch-darkly.properties.erb'
    mode '0700'
    variables(
        :launch_darkly_key => node['xgemail']['launch_darkly_sandbox']
    )
  end
 end
end

# Create a sym link to xgemail-jilter
link "#{DEPLOYMENT_DIR}/xgemail-jilter-#{DIRECTION}" do
  to "#{DEPLOYMENT_DIR}/#{JILTER_PACKAGE_NAME}"
end