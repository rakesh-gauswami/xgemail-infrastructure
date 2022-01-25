#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Allows modification of both brands and free mail domains used during
# impersonation detection.
#
# Examples
# --------
#
# A) Run script without paramters to see available flags and arguments:
#
# python /opt/sophos/xgemail/utils/impersonation_updater.py
#
# A) Download current brands and free-mail-domains:
#
# python /opt/sophos/xgemail/utils/impersonation_updater.py -r eu-west-1 -e dev -w -g brands
# python /opt/sophos/xgemail/utils/impersonation_updater.py -r eu-west-1 -e dev -w -g domains
#
# B) Update brand and free-mail-domains:
#
# python /opt/sophos/xgemail/utils/impersonation_updater.py -r eu-west-1 -e dev -u /tmp/brands.json
# python /opt/sophos/xgemail/utils/impersonation_updater.py -r eu-west-1 -e dev -u /tmp/domains.json
#
# Copyright: Copyright (c) 1997-2019. All rights reserved.
# Company: Sophos Limited or one of its affiliates.

import sys
sys.path.append("/opt/sophos/xgemail/utils")

import argparse
import json
import os
import pip
import sys
import formatterutils

from awshandler import AwsHandler

try:
    from prettytable import PrettyTable
except ImportError:
    pip.main(['install', 'PrettyTable'])
    from prettytable import PrettyTable

# Constants
MAGIC_NUMBER = b'\0SOPHCONFIG'
POLICY_BUCKET_NAME = 'private-cloud-{}-{}-cloudemail-xgemail-policy'
PATH = 'config/inbound-relay-control/impersonation'
BRANDS_FILE = 'brands'
FREE_MAIL_DOMAINS_FILE = 'domains'

# declares all the regions per environment where the
# impersonation microservice is deployed
regions = {
    'dev': ['eu-west-1'],
    'qa': ['eu-west-1', 'eu-central-1', 'us-west-2'],
    'prod': ['eu-west-1', 'eu-central-1', 'us-west-2', 'us-east-2']
}

# the account IDs for the different AWS environments
account_ids = {
    'dev': '750199083801',
    'qa': '382702281923',
    'prod': '202058678495'
}

file_types = {
    BRANDS_FILE: 'brands',
    FREE_MAIL_DOMAINS_FILE: 'free_mail_domains'
}

def is_valid_format(magic_bytes):
    """
     Confirms that the provided file is of the correct file format
    """
    return formatterutils.is_correct_file_format(magic_bytes, MAGIC_NUMBER)

def get_binary(formatted_file):
    """
    Verifies that the magic number matches, decompresses the file and
    returns the content as a string
    """
    magic_number_length = len(MAGIC_NUMBER)
    nonce_length_start_idx = 8 + magic_number_length
    nonce_length_end_idx = 12 + magic_number_length

    if not is_valid_format(formatted_file[0:len(MAGIC_NUMBER)]):
        raise ValueError("File format error: invalid magic bytes!")

    if not formatterutils.is_unencypted_data(formatted_file[nonce_length_start_idx:nonce_length_end_idx]):
        raise ValueError("File format error: invalid nonce length bytes!")

    return formatterutils.get_decompressed_object_bytes(
        formatted_file[nonce_length_end_idx:len(formatted_file)]
    )

def print_brands(deserialized_content):
    """
    Prety-prints the currently stored brands
    """
    config = json.loads(deserialized_content)
    t = PrettyTable(['Name', 'Display Names', 'Display Name Words', 'Domains'])
    t.align = 'l'
    for b in config['brands']:
        dns = ', '.join(b['display_names'])
        words = ', '.join(b['display_name_words'])
        domains = ', '.join(b['org_domains'])
        t.add_row([b['brand_name'], dns, words, domains])
    print t

def print_free_mail_domains(deserialized_content):
    """
    Prety-prints the currently stored free mail domains
    """
    config = json.loads(deserialized_content)
    t = PrettyTable(['Free Mail Domains'])
    t.align = 'l'
    for domain in config['domains']:
        t.add_row([domain])
    print t

def write_config(file_name, deserialized_content):
    """
    Writes the provided config as a JSON document
    """
    path = '/tmp/{}.json'.format(file_name)
    with open(path, 'w') as f:
        f.write(
            json.dumps(
                json.loads(deserialized_content),
                indent=4,
                sort_keys=True
            )
        )
        f.write('\n')
    print 'Wrote {} to file {}'.format(file_name, path)

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(description = 'Impersonation Updater')
    parser.add_argument('-r, --region',
        dest = 'region',
        choices = ['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'],
        required = True,
        help = 'The region where the script is executed'
    )
    parser.add_argument('-e, --env',
        dest = 'env',
        choices = ['dev', 'qa', 'prod'],
        required = True,
        help = 'The environment where the script is executed'
    )
    parser.add_argument('-g', '--get',
        dest = 'config_file',
        choices = [BRANDS_FILE, FREE_MAIL_DOMAINS_FILE],
        help = 'Returns the current configuration'
    )
    parser.add_argument('-w', '--write',
        dest = 'write_file',
        action = 'store_true',
        help = 'Write currently stored configuration'
    )
    parser.add_argument('-u', '--upload',
        dest = 'upload_file',
        help = 'Uploads the provided file'
    )

    args = parser.parse_args()

    awshandler = AwsHandler(args.region)
    bucket_name = POLICY_BUCKET_NAME.format(args.env, args.region)
    brands_path = '{}/{}.json'.format(PATH, file_types[BRANDS_FILE])
    free_mail_domains_path = '{}/{}.json'.format(PATH, file_types[FREE_MAIL_DOMAINS_FILE])

    if args.config_file:
        config_path = '{}/{}.json'.format(PATH, file_types[args.config_file])

        serialized_content = awshandler.download_data_from_s3(
            bucket_name,
            config_path
        )

        deserialized_content = get_binary(serialized_content)

        if args.config_file == BRANDS_FILE:
            print_brands(deserialized_content)
        elif args.config_file == FREE_MAIL_DOMAINS_FILE:
            print_free_mail_domains(deserialized_content)
        else:
            raise ValueError('Invalid config_file {}'.format(args.config_file))
        if args.write_file:
            write_config(args.config_file, deserialized_content)
    elif args.upload_file:
        with open(args.upload_file, 'r') as f:
            content = f.read()
        print 'Uploading file {} to regions {}/{}'.format(
            args.upload_file,
            args.env,
            regions[args.env]
        )

        if 'brands' in json.loads(content):
            sqs_name = 'brands-updater'
        elif 'domains' in json.loads(content):
            sqs_name = 'free-mail-domains-updater'
        else:
            raise ValueError('Invalid input file {}'.format(args.upload_file))

        for cur_region in regions[args.env]:
            account_id = account_ids[args.env]
            sqs_url = 'https://sqs.{}.amazonaws.com/{}/tf-impersonation-{}-{}-sqs'.format(
                cur_region,
                account_id,
                sqs_name,
                cur_region
            )
            print 'Sending job to SQS {}'.format(sqs_url)
            awshandler.add_to_sqs(sqs_url, content)
    else:
        print 'No action taken, exiting.'
