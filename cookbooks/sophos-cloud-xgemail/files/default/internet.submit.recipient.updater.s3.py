#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Polls XGEMAIL PIC for a list of recipients
#
# Copyright: Copyright (c) 1997-2016. All rights reserved.
# Company: Sophos Limited or one of its affiliates.

from multiprocessing.dummy import Pool as ThreadPool
import base64
import boto3
import base64
import json
import os
import requests
import subprocess
import logging
import sys
from logging.handlers import SysLogHandler

# Constants
PIC_CA_PATH = '/etc/ssl/certs/hmr-infrastructure-ca.crt'
PIC_FQDN = 'mail-cloudstation-eu-west-1.dev.hydra.sophos.com'
POSTFIX_INSTANCE_NAME = 'postfix-is'
# RECIPIENT_ACCESS_FILENAME = 'recipient_access'
# FIXME: switch to above filename once testing is done
RECIPIENT_ACCESS_FILENAME = 'recipient_access.s3'
RELAY_DOMAINS_FILENAME = 'relay_domains'

POSTFIX_CONFIG_DIR = subprocess.check_output(
    [
      'postmulti', '-i', POSTFIX_INSTANCE_NAME, '-x',
      'postconf','-h','config_directory'
    ]
).rstrip()

RECIPIENT_ACCESS_FILE = POSTFIX_CONFIG_DIR + '/' + RECIPIENT_ACCESS_FILENAME
RECIPIENT_ACCESS_FILE_TMP = RECIPIENT_ACCESS_FILE + '.tmp'
RELAY_DOMAINS_FILE = POSTFIX_CONFIG_DIR + '/' + RELAY_DOMAINS_FILENAME
POLICY_BUCKET = 'private-cloud-dev-eu-west-1-cloudemail-xgemail-policy'
S3_BUCKET = boto3.resource('s3').Bucket(name = POLICY_BUCKET)
S3_CRAWL_THREADS = 10

# logging to syslog setup
logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger('is-recipient-updater')
logger.setLevel(logging.INFO)
handler = logging.handlers.SysLogHandler('/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
handler.formatter = formatter
logger.addHandler(handler)

def retrieve_recipients_from_s3(domain):
  base_prefix = 'config/policies/domains'
  prefix_with_domain = '{}/{}/'.format(base_prefix, domain)

  recipients = set()
  for obj in S3_BUCKET.objects.filter(Prefix = prefix_with_domain):
    base_64_encoded_localpart = obj.key.split('/')[4]
    localpart = base64.b64decode(base_64_encoded_localpart)
    email_address = '{}@{}'.format(localpart, domain)
    recipients.add(email_address)
  return recipients

domains = []
with open(RELAY_DOMAINS_FILE, 'r') as f:
  for domain in f.readlines():
    # file is formatted like so:
    #   example1.com OK
    #   example2.com OK
    #   ...
    # but we only need the domain name
    domains.append(domain.split(' ')[0])

recipients = set()

# make the Pool of workers
pool = ThreadPool(S3_CRAWL_THREADS)

# retrieve recipients by domain from S3 using threads
results = pool.map(retrieve_recipients_from_s3, domains)

# close the pool and wait for the work to finish
pool.close()
pool.join()

for thread_result in results:
    recipients.update(thread_result)

with open(RECIPIENT_ACCESS_FILE_TMP, 'w') as f:
  for recipient in recipients:
    f.write('{0} OK\n'.format(recipient.encode("utf-8")))

# FIXME: change once testing is done
# subprocess.call(['postmap', 'hash:{0}'.format(RECIPIENT_ACCESS_FILE_TMP)])
# os.rename(RECIPIENT_ACCESS_FILE_TMP, RECIPIENT_ACCESS_FILE)
# os.rename(RECIPIENT_ACCESS_FILE_TMP + '.db', RECIPIENT_ACCESS_FILE + '.db')

logger.info('recipient access file [%s.db] successfully updated', RECIPIENT_ACCESS_FILE)
