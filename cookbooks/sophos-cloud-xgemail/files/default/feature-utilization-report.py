#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Generates a utilization report of how Sophos Email features
#
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#

import sys
sys.path.append('/opt/sophos/xgemail/utils')

import argparse
import base64
import boto3
import json
import formatterutils
import logging
import os
import subprocess
import sys
import time

from datetime import date
from datetime import datetime
from functools import partial
from logging.handlers import SysLogHandler
from multiprocessing.dummy import Pool as ThreadPool

# Constants
BASE_DOMAINS_PREFIX = 'config/policies/domains'
POSTFIX_INSTANCE_NAME = 'postfix-is'

RECIPIENT_ACCESS_FILENAME_ENABLED = 'recipient_access'
RECIPIENT_ACCESS_FILENAME_DRYRUN = 'recipient_access.dryrun'
S3_CRAWL_THREADS = 5

POLICY_MAGIC_BYTES = b'\0SOPHPOLCY'

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

def get_binary(formatted_file, magic_number):
    """
	Verifies that the magic number matches, decompresses the file and
	returns the content as a string
    """
    magic_number_length = len(magic_number)
    nonce_length_start_idx = 8 + magic_number_length
    nonce_length_end_idx = 12 + magic_number_length

    return formatterutils.get_decompressed_object_bytes(
	    formatted_file[nonce_length_end_idx:len(formatted_file)]
    )

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

def read_policy_files(s3_bucket, max_policies_to_analyze, pretty_print):
    """
       Reads all endpoint policy files and creates a utilization
       report based on those files
    """
    policies = set()
    policy_results = {}
    policies_disabled = 0
    user_results = {}
    counter = 0

    if max_policies_to_analyze <= 0:
        print 'Calculating number of endpoint policies...'
        total_policies = sum(1 for _ in s3_bucket.objects.filter(Prefix = 'config/policies/endpoints'))
    else:
        total_policies = max_policies_to_analyze
    print 'Total endpoint policies: {}'.format(total_policies)
    for obj in s3_bucket.objects.filter(Prefix = 'config/policies/endpoints'):
        if counter > 0 and counter % 100 == 0:
            print 'Endpoint policies analyzed: {}/{} ({}%)'.format(counter, total_policies, float(counter)/float(total_policies) * 100)
        if counter > 0 and counter % 1000 == 0:
            print 'Current policy result:\n'
            create_report(policy_results, pretty_print)
            print
            print 'Current user result:\n'
            create_report(user_results, pretty_print)
        if counter >= max_policies_to_analyze and max_policies_to_analyze > 0:
            break

        policy = json.loads(get_binary(obj.get()['Body'].read(), POLICY_MAGIC_BYTES))
        policyId = policy['policyId']

        try:
            policy_attributes = policy['policyAttributes']

            if 'xgemail/has_feature' not in policy_attributes or not policy_attributes['xgemail/has_feature']:
                policies_disabled+=1
                counter+=1
                continue

            if 'emailAddresses' in policy:
                nr_of_email_addresses = len(policy['emailAddresses'])
            else:
                nr_of_email_addresses = 1

            policy_already_covered = False
            if policyId in policies:
                policy_already_covered = True
            else:
                policies.add(policyId)

            for k, v in policy_attributes.iteritems():
                value_as_string = u'{}'.format(v)

                if not policy_already_covered:
                    # populate policy result
                    if k in policy_results:
                        cur_val = policy_results[k]
                        if value_as_string in cur_val:
                            cur_val[value_as_string] += 1
                        else:
                            policy_results[k][value_as_string] = 1
                    else:
                        policy_results[k] = {value_as_string : 1}

                # populate user result
                if k in user_results:
                    cur_val = user_results[k]
                    if value_as_string in cur_val:
                        cur_val[value_as_string] += nr_of_email_addresses
                    else:
                        user_results[k][value_as_string] = nr_of_email_addresses
                else:
                    user_results[k] = {value_as_string : nr_of_email_addresses}
            counter+=1
        except Exception as e:
            print 'Unable to parse policy {} - {}: {}'.format(policyId, obj.key, e)
    print 'Total unique policies analyzed: {}'.format(len(policies))
    print 'Total policies disabled: {}'.format(policies_disabled)
    return {'policy results': policy_results, 'user results': user_results}

def create_report(policy_files_result, pretty_print):
    if pretty_print:
        print json.dumps(policy_files_result, indent=4, sort_keys=True)
    else:
        print json.dumps(policy_files_result)

if __name__ == "__main__":
    """
        Entrypoint into this script. In order to run, it requires at the very least
        both the --env and the --region parameters otherwise the script will
        exit without retrieving any data from S3.
    """
    parser = argparse.ArgumentParser(description = 'Retrieve Sophos Email recipients from S3')
    parser.add_argument('--env', choices=['dev', 'dev3', 'qa', 'prod','inf'], help = 'the environment in which this script runs', required = True)
    parser.add_argument('--region', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'the region in which this script runs', required = True)
    parser.add_argument('--size', default = 0, help = 'number of endpoint policies to read from S3. Use 0 (default) for all.')
    parser.add_argument('--prettyprint', dest='prettyprint', action = 'store_true', help = 'Pretty print JSON output')

    args = parser.parse_args()

    policy_bucket = 'private-cloud-{}-{}-cloudemail-xgemail-policy'.format(args.env, args.region)
    s3_bucket = boto3.resource('s3').Bucket(name = policy_bucket)

    postfix_config_dir = subprocess.check_output([
        'postmulti', '-i', POSTFIX_INSTANCE_NAME, '-x',
        'postconf','-h','config_directory'
    ]).rstrip()

    relay_domains_file = postfix_config_dir + '/relay_domains'
    domains = read_domains_from_file(relay_domains_file)

    results = read_policy_files(s3_bucket, int(args.size), args.prettyprint)
    for k, v in results.iteritems():
        print '{}:'.format(k)
        create_report(v, args.prettyprint)
