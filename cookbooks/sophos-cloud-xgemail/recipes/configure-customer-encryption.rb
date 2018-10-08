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

## The Postfix instance name for the customer-encryption node
CUSTOMER_ENCRYPTION_POSTFIX_INSTANCE_NAME = 'ed'

include_recipe 'sophos-cloud-xgemail::configure-customer-encryption-delivery-queue'

CUSTOMER_ENCRYPTION_POSTFIX_INSTANCE_NAME = 'es'
include_recipe 'sophos-cloud-xgemail::configure-customer-encryption-submit-queue'