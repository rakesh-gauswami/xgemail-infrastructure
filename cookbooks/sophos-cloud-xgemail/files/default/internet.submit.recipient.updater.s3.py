#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Retrieves valid Sophos Email recipients from S3
#
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#

import argparse
import base64
import boto3
import logging
import os
import subprocess
import sys

from functools import partial
from logging.handlers import SysLogHandler
from multiprocessing.dummy import Pool as ThreadPool

# Constants
BASE_DOMAINS_PREFIX = 'config/policies/domains'
POSTFIX_INSTANCE_NAME = 'postfix-is'

RECIPIENT_ACCESS_FILENAME_ENABLED = 'recipient_access'
RECIPIENT_ACCESS_FILENAME_DRYRUN = 'recipient_access.dryrun'

RELAY_DOMAINS_FILENAME = 'relay_domains'

POSTFIX_CONFIG_DIR = subprocess.check_output([
    'postmulti', '-i', POSTFIX_INSTANCE_NAME, '-x',
    'postconf','-h','config_directory'
]).rstrip()

RELAY_DOMAINS_FILE = POSTFIX_CONFIG_DIR + '/' + RELAY_DOMAINS_FILENAME
S3_CRAWL_THREADS = 5

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

def read_domains_from_file(file_path):
    domains = []
    with open(RELAY_DOMAINS_FILE, 'r') as f:
        for domain in f.readlines():
            # file is formatted like so:
            #   example1.com OK
            #   example2.com OK
            #   ...
            # but we only need the domain name
            domains.append(domain.split(' ')[0])
    return domains

def retrieve_recipients_from_s3(s3_bucket, domain):
    prefix_with_domain = '{}/{}/'.format(BASE_DOMAINS_PREFIX, domain)

    recipients = set()
    for obj in s3_bucket.objects.filter(Prefix = prefix_with_domain):
        try:
            recipients.add(decode_email_address(obj.key, domain))
        except:
            logger.error('Error when attempting to decode key {}'.format(obj.key))
    return recipients

def decode_email_address(local_part_with_prefix, domain):
    base_64_encoded_localpart = local_part_with_prefix.split('/')[4]
    localpart = base64.b64decode(base_64_encoded_localpart)
    email_address = '{}@{}'.format(localpart, domain)
    return email_address

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = 'Retrieve Sophos Email recipients from S3')
    parser.add_argument('--env', choices=['dev', 'dev3', 'qa', 'prod','inf'], help = 'the environment in which this script runs', required = True)
    parser.add_argument('--region', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'the region in which this script runs', required = True)
    parser.add_argument('--enabled', action = 'store_true', help = 'if set then this script will update the actual live recipient file and reload Postfix')
    parser.add_argument('--dryrun', action = 'store_true', help = 'if set then this script will retrieve recipients from S3 but store it in a temporary file')

    args = parser.parse_args()

    if not args.enabled and not args.dryrun:
        # do not execute this script, it's neither enabled nor a dryrun was requested
        sys.exit(0)

    policy_bucket = 'private-cloud-{}-{}-cloudemail-xgemail-policy'.format(args.env, args.region)
    s3_bucket = boto3.resource('s3').Bucket(name = policy_bucket)

    domains = read_domains_from_file(RELAY_DOMAINS_FILE)

    # make the Pool of workers
    pool = ThreadPool(S3_CRAWL_THREADS)

    # retrieve recipients by domain from S3 using multi-threading
    results = pool.map(
        partial(retrieve_recipients_from_s3, s3_bucket),
        domains
    )

    # close the pool and wait for the work to finish
    pool.close()
    pool.join()

    recipients = set()
    for thread_result in results:
        recipients.update(thread_result)

    if args.enabled:
        recipient_access_file = POSTFIX_CONFIG_DIR + '/' + RECIPIENT_ACCESS_FILENAME_ENABLED
    elif args.dryrun:
        recipient_access_file = POSTFIX_CONFIG_DIR + '/' + RECIPIENT_ACCESS_FILENAME_DRYRUN
    else:
        logger.warn('Script did not run in enabled or dryrun mode, exiting.')
        sys.exit(1)

    recipient_access_file_tmp = recipient_access_file + '.tmp'

    with open(recipient_access_file_tmp, 'w') as f:
        for recipient in recipients:
            try:
                f.write('{0} OK\n'.format(recipient.encode("utf-8")))
            except UnicodeDecodeError:
                logger.error('Exception when attempting to write recipient {}'.format(recipient))

    if args.enabled:
        subprocess.call(['postmap', 'hash:{0}'.format(recipient_access_file_tmp)])
        os.rename(recipient_access_file_tmp, recipient_access_file)
        os.rename(recipient_access_file_tmp + '.db', recipient_access_file  + '.db')

        logger.info('Recipient access file [%s.db] successfully updated', recipient_access_file)
