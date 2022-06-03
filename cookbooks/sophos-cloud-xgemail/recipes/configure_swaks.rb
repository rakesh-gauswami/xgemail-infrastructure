#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure_swaks
#
# Copyright 2022, Sophos
#
# All rights reserved - Do Not Redistribute
#
# Description
#

# Include Helper library
::Chef::Recipe.send(:include, ::SophosCloudXgemail::Helper)
::Chef::Resource.send(:include, ::SophosCloudXgemail::Helper)

AWS_REGION   = node['sophos_cloud']['region']
ACCOUNT_NAME = node['sophos_cloud']['account_name']
NODE_TYPE    = node['xgemail']['cluster_type']

PACKAGES_DIR = '/opt/sophos/packages'

INSTANCE_DATA = node['xgemail']['postfix_instance_data'][NODE_TYPE]
raise "Unsupported node type [#{NODE_TYPE}]" if INSTANCE_DATA.nil?

INSTANCE_NAME = INSTANCE_DATA[:instance_name]
raise "Invalid instance name for node type [#{NODE_TYPE}]" if INSTANCE_NAME.nil?

SWAKS_DIR = '/opt/swaks'
SWAKS_SEND_WARMUP_EMAILS = 'send_warmup_emails.sh'
SWAKS_UPDATE_SUBJECTS    = 'update_subjects.sh'
SWAKS_SUBJECT_LISTS      = 'subject_lists.txt'
SWAKS_SEND_20_EMAILS     = 'send_20_emails.sh'
SWAKS_SEND_50_EMAILS     = 'send_50_emails.sh'

directory SWAKS_DIR do
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end

bash 'download_swaks' do
  user 'root'
  cwd SWAKS_DIR
  code <<-EOH
    cp #{PACKAGES_DIR}/swaks #{SWAKS_DIR}
    /bin/chmod +x #{SWAKS_DIR}/swaks
  EOH
end

template SWAKS_SEND_WARMUP_EMAILS do
  path "#{SWAKS_DIR}/#{SWAKS_SEND_WARMUP_EMAILS}"
  source "xgemail.swaks.send.warmup.emails.#{AWS_REGION}.sh.erb"
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :aws_region => AWS_REGION,
    :SWAKS_DIR => SWAKS_DIR
  )
end

template SWAKS_SUBJECT_LISTS do
  path "#{SWAKS_DIR}/#{SWAKS_SUBJECT_LISTS}"
  source 'xgemail.swaks.subject.lists.txt.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template SWAKS_UPDATE_SUBJECTS do
  path "#{SWAKS_DIR}/#{SWAKS_UPDATE_SUBJECTS}"
  source 'xgemail.swaks.update.subjects.sh.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :SWAKS_DIR => SWAKS_DIR
  )
end

template SWAKS_SEND_20_EMAILS do
  path "#{SWAKS_DIR}/#{SWAKS_SEND_20_EMAILS}"
  source 'xgemail.swaks.send.20.emails.sh.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :SWAKS_DIR => SWAKS_DIR
  )
end

template SWAKS_SEND_50_EMAILS do
  path "#{SWAKS_DIR}/#{SWAKS_SEND_50_EMAILS}"
  source 'xgemail.swaks.send.50.emails.sh.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :SWAKS_DIR => SWAKS_DIR
  )
end

cron SWAKS_UPDATE_SUBJECTS do # Update subjectline of the emails
  minute '*/10'
  user 'root'
  command "/bin/bash #{SWAKS_DIR}/#{SWAKS_UPDATE_SUBJECTS}"
end

cron SWAKS_SEND_WARMUP_EMAILS do # runs 1time/mins on Weekends
  user 'root'
  weekday '0,6'
  command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_WARMUP_EMAILS}"
end

if AWS_REGION == 'ca-central-1'
  cron SWAKS_SEND_20_EMAILS do # runs twice/min during off hours during weekdays
    minute '*/5'
    hour '00-14,21-23'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_20_EMAILS}"
  end

  cron SWAKS_SEND_50_EMAILS do # send 50 email in every 5mins during peak hour
    minute '*/5'
    hour '15-20'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_50_EMAILS}"
  end

elsif AWS_REGION == 'eu-west-1'
  cron SWAKS_SEND_20_EMAILS do # runs twice/min during off hours during weekdays
    minute '*/5'
    hour '13-14,21-23'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_20_EMAILS}"
  end

  cron SWAKS_SEND_50_EMAILS do # send 50 email in every 5mins during peak hour
    minute '*/5'
    hour '00-12'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_50_EMAILS}"
  end

elsif AWS_REGION == 'ap-southeast-2'
  cron SWAKS_SEND_20_EMAILS do # runs twice/min during off hours during weekdays
    minute '*/5'
    hour '22-23,00-06'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_20_EMAILS}"
  end

  cron SWAKS_SEND_50_EMAILS do # send 50 email in every 5mins during peak hour
    minute '*/5'
    hour '07-21'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_50_EMAILS}"
  end

elsif AWS_REGION == 'ap-northeast-1'
  cron SWAKS_SEND_20_EMAILS do # runs twice/min during off hours during weekdays
    minute '*/5'
    hour '12-23,9-11'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_20_EMAILS}"
  end

  cron SWAKS_SEND_50_EMAILS do # send 50 email in every 5mins during peak hour
    minute '*/5'
    hour '00-08'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_50_EMAILS}"
  end

elsif AWS_REGION == 'ap-south-1'
  cron SWAKS_SEND_20_EMAILS do # runs twice/min during off hours during weekdays
    minute '*/5'
    hour '11-23,00-02'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_20_EMAILS}"
  end

  cron SWAKS_SEND_50_EMAILS do # send 50 email in every 5mins during peak hour
    minute '*/5'
    hour '03-10'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_50_EMAILS}"
  end

elsif AWS_REGION == 'sa-east-1'
  cron SWAKS_SEND_20_EMAILS do # runs twice/min during off hours during weekdays
    minute '*/5'
    hour '00-11,20-23'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_20_EMAILS}"
  end

  cron SWAKS_SEND_50_EMAILS do # send 50 email in every 5mins during peak hour
    minute '*/5'
    hour '12-19'
    weekday '1-5'
    user 'root'
    command "/bin/bash #{SWAKS_DIR}/#{SWAKS_SEND_50_EMAILS}"
  end
end
