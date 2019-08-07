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
import getopt

MAIL_PIC_RESPONSE_TIMEOUT = 60

env='dev'
region='eu-west-1'
customerId='null'

myopts, args = getopt.getopt(sys.argv[1:],"e:r:c:")
for o, val in myopts:
  if o == '-e':
      env=val
  elif o == '-r':
      region=val
  elif o == '-c':
      customerId=val
  else:
      print("Sync outbound gateway config file in S3 for the specified cunstomer")
      print("usage: %s -e dev/qa/prod -r {region} -c {customer id}" % sys.argv[0])
      print("Sample usage: %s -e dev -r eu-west-1 -c 3a34a8af-712f-4c82-9edf-7449f04cefd2" % sys.argv[0])

if customerId == 'null':
    print("customer id is required")
    print("usage: %s -e dev/qa/prod -r {region} -c {customer id}" % sys.argv[0])
    sys.exit()

print ("Env : %s, region: %s, customer id: %s" % (env, region, customerId))

#PIC_FQDN = 'mail-cloudstation-eu-west-1.dev.hydra.sophos.com'
#MAIL_PIC_API_AUTH = 'xgemail-eu-west-1-mail'
#CONNECTIONS_BUCKET = 'cloud-dev-connections'
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

