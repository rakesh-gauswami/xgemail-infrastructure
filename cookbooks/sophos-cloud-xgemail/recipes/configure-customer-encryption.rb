#
# Cookbook Name:: sophos-cloud-xgemail
# Recipe:: configure-encryption-delivery-queue
#
# Copyright 2018, Sophos
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures the postfix instances for customer-encryption node
#

NODE_TYPE = node['xgemail']['cluster_type']

if NODE_TYPE != 'customer-encryption'
  return
end

include_recipe 'sophos-cloud-xgemail::configure-customer-encryption-delivery-queue'
#include_recipe 'sophos-cloud-xgemail::configure-customer-encryption-submit-queue'