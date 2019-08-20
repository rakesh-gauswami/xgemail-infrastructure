#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Retrieves missing domains in S3 from Sophos Email domain file
#
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#

import argparse
import boto3
import logging
import subprocess

from logging.handlers import SysLogHandler

# Constants
BASE_DOMAINS_PREFIX = 'config/policies/domains'
POSTFIX_INSTANCE_NAME = 'postfix-is'

MISSING_DOMAINS_IN_S3_FILENAME_DRYRUN = 'missing_domains_in_s3.dryrun.tmp'

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

def retrieve_missing_domains_from_s3(domains, s3_client, bucketName):

    missing_domains = set()

    for domain in domains:
        prefix_with_domain = '{}/{}'.format(BASE_DOMAINS_PREFIX, domain)
        response = s3_client.list_objects(Bucket=bucketName, Prefix = prefix_with_domain)

        if response.get('Contents') is None:
            missing_domains.add(domain)

    return missing_domains


if __name__ == "__main__":
    """
        Entrypoint into this script. In order to run, it requires at the very least
        both the --env and the --region parameters otherwise the script will
        exit without retrieving any data from S3.
    """
    parser = argparse.ArgumentParser(description = 'Retrieve Sophos Email recipients from S3')
    parser.add_argument('--env', choices=['dev', 'dev3', 'qa', 'prod','inf'], help = 'the environment in which this script runs', required = True)
    parser.add_argument('--region', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'the region in which this script runs', required = True)

    args = parser.parse_args()

    policy_bucket = 'private-cloud-{}-{}-cloudemail-xgemail-policy'.format(args.env, args.region)
    s3_bucket = boto3.resource('s3').Bucket(name = policy_bucket)

    postfix_config_dir = subprocess.check_output([
        'postmulti', '-i', POSTFIX_INSTANCE_NAME, '-x',
        'postconf','-h','config_directory'
    ]).rstrip()

    relay_domains_file = postfix_config_dir + '/relay_domains'

    s3client = boto3.client('s3')

    domains = read_domains_from_file(relay_domains_file)
    #domains = {"swatijain.com", "iaxwis2c64.example.com", "70ixv4pn96.example.com", "swatijain2.com"}

    missing_domains_set = retrieve_missing_domains_from_s3(domains, s3client, policy_bucket)

    missing_domains_file_tmp = postfix_config_dir + '/' + MISSING_DOMAINS_IN_S3_FILENAME_DRYRUN

    with open(missing_domains_file_tmp, 'w') as f:
        for missing_domain in missing_domains_set:
            try:
                f.write('{0} OK\n'.format(missing_domain.encode("utf-8")))
            except UnicodeDecodeError:
                logger.error('Exception when attempting to write missing_domain <%s>', missing_domain)

