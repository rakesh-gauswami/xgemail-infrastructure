
# Cookbook Name:: sophos-cloud-common
# Recipe:: ec2-user
#
# Copyright 2016, Sophos
#
# All rights reserved - Do Not Redistribute
#



# this is a recipe for creating the ec2-user when it does not exist ... ie on kitchen/vagrant machines


user 'ec2-user' do
    home '/home/ec2-user'
    shell '/bin/bash'
end

