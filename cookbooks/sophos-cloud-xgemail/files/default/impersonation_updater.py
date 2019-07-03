#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Allows modification of both brands and free mail domains used during
# impersonation detection.
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
POLICY_BUCKET_NAME = 'private-cloud-{}-{}-cloudemail-xgemail-policy'
PATH = 'config/inbound-relay-control/impersonation'
BRANDS_FILE = 'brands'
FREE_MAIL_DOMAINS_FILE = 'free_mail_domains'

def is_valid_format(magic_bytes, magic_number):
    """
     Confirms that the provided file is of the correct file format
    """
    return formatterutils.is_correct_file_format(
        magic_bytes,
        magic_number
    )

def get_binary(formatted_file, magic_number):
    """
    Verifies that the magic number matches, decompresses the file and
    returns the content as a string
    """
    magic_number_length = len(magic_number)
    nonce_length_start_idx = 8 + magic_number_length
    nonce_length_end_idx = 12 + magic_number_length

    if not is_valid_format(formatted_file[0:len(magic_number)], magic_number):
        raise ValueError("File format error: invalid magic bytes!")

    if not formatterutils.is_unencypted_data(formatted_file[nonce_length_start_idx:nonce_length_end_idx]):
        raise ValueError("File format error: invalid nonce length bytes!")

    return formatterutils.get_decompressed_object_bytes(
        formatted_file[nonce_length_end_idx:len(formatted_file)]
    )

def print_brands(deserialized_content):
    """
    Prety-prints the currently stored free mail domains
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
    t = PrettyTable(['Domains'])
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
        f.write(json.dumps(deserialized_content, indent=4, sort_keys=True))
    print 'Wrote {} to file {}'.format(file_name, path)

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(description = 'Impersonation Updater')
    parser.add_argument('-g', '--get', dest = 'config_file',
        choices=[BRANDS_FILE, FREE_MAIL_DOMAINS_FILE],
        help = 'Returns the current configuration'
    )
    parser.add_argument('-w', '--write', dest = 'write_file',
        help = 'Write currently stored configuration'
    )

    args = parser.parse_args()

    # FIXME: get this from somewhere
    env = 'dev'
    region = 'eu-west-1'
    awshandler = AwsHandler('eu-west-1')

    bucket_name = POLICY_BUCKET_NAME.format(env, region)
    brands_path = '{}/{}.json'.format(PATH, BRANDS_FILE)
    free_mail_domains_path = '{}/{}.json'.format(PATH, FREE_MAIL_DOMAINS_FILE)

    if args.config_file:
        config_path = '{}/{}.json'.format(PATH, args.config_file)

        serialized_content = awshandler.download_data_from_s3(
            bucket_name,
            config_path
        )

        deserialized_content = get_binary(serialized_content, b'\0SOPHCONFIG')

        if args.write_file:
            write_config(args.config_file, deserialized_content)

        if args.config_file == BRANDS_FILE:
            print_brands(deserialized_content)
        elif args.config_file == FREE_MAIL_DOMAINS_FILE:
            print_free_mail_domains(deserialized_content)
        else:
            raise ValueError('Invalid config_file {}'.format(args.config_file))
        sys.exit(0)

    #awshandler.add_to_sqs(
    #    'https://sqs.eu-west-1.amazonaws.com/750199083801/tf-impersonation-request-eu-west-1-sqs',
    #    '{"message_path":"messages/2019/06/28/05/51c2ab333791c24360bdf937aa1db29871599412ffa8ffce175beff360e67ca5/172.19.1.248-45Zlg25J0xzFpVN-emaildev1-gl.info.MESSAGE","customer_id":"84e61a73-5e3b-4616-8719-6098a0cb0ede"}'
    #)
