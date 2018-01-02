#
# Cookbook Name:: sophos-cloud-common
# Recipe:: set_version_tags
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#

# The following assignments rely on execution of the Ohai EC2 plugin.
# See: http://bdwyertech.net/2015/04/24/chef-ohai-in-aws-ec2-vpc/

INSTANCE_ID = node["ec2"]["instance_id"]
REGION      = node['ec2']['placement_availability_zone'][0...-1]

# Set version tags for display by the cloud list command.

# TODO: Handle other versions, e.g. WebappVersion.

# TODO: Consider getting around tag limits by registering versions
#       (and maybe other instance data) in SimpleDb or DynamoDb.

bash "create KernelVersion tag" do
  user "root"
  code <<-EOH
    version="$(/bin/uname -r)"
    /usr/bin/aws ec2 create-tags \
        --region "#{REGION}" \
        --resources "#{INSTANCE_ID}" \
        --tags Key=KernelVersion,Value="${version}" || :
  EOH
end

bash "create MongoVersion tag" do
  user "root"
  code <<-EOH
    version="$(/usr/bin/mongo --version | awk 'NR==1 {print $NF}')"
    /usr/bin/aws ec2 create-tags \
        --region "#{REGION}" \
        --resources "#{INSTANCE_ID}" \
        --tags Key=MongoVersion,Value="${version}" || :
  EOH
  only_if { ::File.exists?("/usr/bin/mongo") }
end
