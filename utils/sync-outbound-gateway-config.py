#!/usr/bin/env python

# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Update outbound gateway config files in Amazon S3 bucket, 
#        private-cloud-prod-eu-west-1-cloudemail-xgemail-policy/config/policies/domains/{customer-domain}, 
# for domains belongs to the specified customer.
#
# This script can be executed on cloud email instances from /opt/sophos/xgemail/utils
#

import boto3
import base64
import json
import os
import requests
import subprocess
import sys
import argparse

MAIL_PIC_RESPONSE_TIMEOUT = 60

# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(description="Sync outbound gateway config file in S3 for the specified cunstomer.")
    parser.add_argument("--region", "-r", dest='region', default='eu-west-1', choices=['eu-west-1', 'eu-central-1', 'us-west-2','us-east-2'])
    parser.add_argument("--environment", "-e", dest='env', default='dev', choices=['dev', 'qa', 'prod'])
    parser.add_argument("--customer", "-c", dest='customerid', required=True, help="Enter customer id")

    return parser.parse_args()

args = parse_command_line()

env=args.env
region=args.region
customerId=args.customerid

print ("env : %s, region: %s, customer id: %s" % (env, region, customerId))

pic_fqdn = "mail-cloudstation-{}.{}.hydra.sophos.com".format(region, env)
mail_pic_api_auth = "xgemail-{}-mail".format(region)
connections_bucket =  "cloud-{}-connections".format(env)

print ("pic_fqdn : %s" % (pic_fqdn))
print ("mail_pic_api_auth : %s" % (mail_pic_api_auth))
print ("connections_bucket : %s" % (connections_bucket))

def get_passphrase():
    s3 = boto3.client('s3')
    passphrase = s3.get_object(Bucket=connections_bucket, Key=mail_pic_api_auth)
    return base64.b64encode('mail:' + passphrase['Body'].read())
  
auth = get_passphrase()
  
HEADERS = {
    'Content-type': 'application/json',
    'Authorization': 'Basic ' + auth
}
PIC_XGEMAIL_API_URL = 'https://%s/mail/api/xgemail' % (pic_fqdn)
print('internet submit domains cron - pic url ', PIC_XGEMAIL_API_URL)

PIC_DOMAINS_URL = PIC_XGEMAIL_API_URL + '/sync-outbound-gateway-config/' + customerId  
print('Sending request URL - ', PIC_DOMAINS_URL)
  
response = requests.post(
    PIC_DOMAINS_URL,
    headers=HEADERS,
    timeout=MAIL_PIC_RESPONSE_TIMEOUT
)
response.raise_for_status()

print('Response for Sync Outbound Gateway Config - ', response)

