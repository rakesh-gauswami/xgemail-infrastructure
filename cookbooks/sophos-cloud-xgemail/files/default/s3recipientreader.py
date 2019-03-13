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
S3_CRAWL_THREADS = 5

# logging to syslog setup
logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger('s3recipientreader')
logger.setLevel(logging.INFO)
handler = logging.handlers.SysLogHandler('/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
handler.formatter = formatter
logger.addHandler(handler)

def read_domains_from_file(relay_domains_file):
    """
        Reads the file at the provided location and returns
        the list of domains. This method assumes that the
        file is of the following format:

        example1.com OK
        example2.com OK
        ...
    """
    domains = []
    with open(relay_domains_file, 'r') as f:
        for domain in f.readlines():
            domains.append(domain.split(' ')[0])
    return domains

def retrieve_recipients_from_s3(s3_bucket, domain):
    """
       Reads all objects under a given prefix from S3.
       Returns a list of recipients as valid email addresses.
    """
    prefix_with_domain = '{}/{}/'.format(BASE_DOMAINS_PREFIX, domain)

    recipients = set()
    for obj in s3_bucket.objects.filter(Prefix = prefix_with_domain):
        try:
            recipients.add(decode_email_address(obj.key))
        except:
            logger.error('Error when attempting to decode key {}'.format(obj.key))
    return recipients

def decode_email_address(s3_path_with_domain_and_recipient):
    """
        Extracts both the base64 encoded localpart as well as
        the domain from the provided string. It then decodes the localpart
        and returns the complete email address.

        The expected format of the provided string is as follows:

        config/policies/domains/<domain-name>/<base64-encoded-localpart>

        e.g.

        config/policies/domains/lion.com/aGFrdW5hLm1hdGF0YQ==
    """
    tokens = s3_path_with_domain_and_recipient.split('/')
    domain = tokens[3]
    base_64_encoded_localpart = tokens[4]

    localpart = base64.b64decode(base_64_encoded_localpart)
    email_address = '{}@{}'.format(localpart, domain)
    return email_address

if __name__ == "__main__":
    """
        Entrypoint into this script. In order to run, it requires at the very least
        both the --env and the --region parameters otherwise the script will
        exit without retrieving any data from S3.
    """
    parser = argparse.ArgumentParser(description = 'Retrieve Sophos Email recipients from S3')
    parser.add_argument('--env', choices=['dev', 'dev3', 'qa', 'prod','inf'], help = 'the environment in which this script runs', required = True)
    parser.add_argument('--region', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'the region in which this script runs', required = True)
    parser.add_argument('--enabled', action = 'store_true', help = 'if set then this script will update the actual live recipient file and reload Postfix')
    parser.add_argument('--dryrun', action = 'store_true', help = 'if set then this script will retrieve recipients from S3 but store it in a temporary file')

    args = parser.parse_args()

    if not args.enabled and not args.dryrun:
        # do not execute this script, it's neither enabled nor a dryrun was requested
        logger.debug('Script is neither enabled nor set to perform a dry run, exiting.')
        sys.exit(0)

    policy_bucket = 'private-cloud-{}-{}-cloudemail-xgemail-policy'.format(args.env, args.region)
    s3_bucket = boto3.resource('s3').Bucket(name = policy_bucket)

    postfix_config_dir = subprocess.check_output([
        'postmulti', '-i', POSTFIX_INSTANCE_NAME, '-x',
        'postconf','-h','config_directory'
    ]).rstrip()

    relay_domains_file = postfix_config_dir + '/relay_domains'

    domains = read_domains_from_file(relay_domains_file)

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
        recipient_access_file = postfix_config_dir + '/' + RECIPIENT_ACCESS_FILENAME_ENABLED
    elif args.dryrun:
        recipient_access_file = postfix_config_dir + '/' + RECIPIENT_ACCESS_FILENAME_DRYRUN
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
