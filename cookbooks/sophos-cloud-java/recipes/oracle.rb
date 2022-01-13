#============================================================================
# 
# java.rb
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#
#============================================================================
#
# Installs the jdk from the Oracle download site. 
#
#============================================================================

dependency_bucket_name = "cloud-#{node[:sophos_cloud][:environment]}-3rdparty"
java_home = node[:java][:home]
version = node[:java][:version]

if version == 8
    url = 'http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz'
    file_name = 'jdk1.8.0_311'
else 
    url = 'http://download.oracle.com/otn-pub/java/jdk/7u67-b01/jdk-7u67-linux-x64.tar.gz'
    file_name = 'jdk1.7.0_67' 
end

#----------------------------------------------------------------------------
# JDK
#----------------------------------------------------------------------------
bash 'download jdk' do
  user 'root'
  cwd '/opt'
  code <<-EOH
      aws s3 --region us-west-2 cp s3://#{dependency_bucket_name}/jdk/#{file_name}.tar.gz /opt/#{file_name}.tar.gz | true
  EOH
  not_if { File.exists?("/opt/#{file_name}.tar.gz") }
end

remote_file "/opt/#{file_name}.tar.gz" do
	source url
	headers('Cookie' => 'oraclelicense=accept-securebackup-cookie')
	owner 'root'
	group 'root'
	mode 0664
    not_if { File.exists?("/opt/#{file_name}.tar.gz") }
end

#----------------------------------------------------------------------------
bash 'install jdk' do
	creates "/opt/#{file_name}"
	user 'root'
	umask 022
	cwd '/opt'
    code <<-EOH
        tar -xzf /opt/#{file_name}.tar.gz
        chown -R root:root /opt/#{file_name}
    EOH
end

#----------------------------------------------------------------------------
link java_home do
    to "/opt/#{file_name}"
end
