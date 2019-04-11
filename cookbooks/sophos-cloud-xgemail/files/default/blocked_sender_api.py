#!/usr/bin/env python
# -*- encoding: utf-8 -*-
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This script can be used to retrieve existing blocked/blacklisted entries,
# block new addresses or unblock existing entries.
#
# Run this script on a customer-submit (e.g. CloudEmail:customer-submit). Make
# sure you are in the appropriate AWS environment.
#
# Examples:
#
# Retrieve all currently blocked entries:
# python block_sender_api.py --get
#
# Block an address:
# python block_sender_api.py --block bad@guy.com
#
# Block a domain:
# python block_sender_api.py --block guy.com
#
# Unblock an address by ID:
# python block_sender_api.py --unblock 5c152e2e3d282611d34c25a8
#

import argparse
import base64
import boto3
import json
import requests
import sys
import urllib3

from email.utils import parseaddr

MAIL_PIC_RESPONSE_TIMEOUT = 30

def get_passphrase(connections_bucket, mail_pic_api_auth):
    """
    Retrieves the passphrase required for authenticating with
    the Xgemail Mail PIC API from the appropriate S3 bucket
    """
    s3 = boto3.client('s3')
    passphrase = s3.get_object(Bucket=connections_bucket, Key=mail_pic_api_auth)
    return base64.b64encode('mail:' + passphrase['Body'].read())

def block_entry(url, entry, headers):
    """
    Performs a POST request to permanently block the provided address or domain
    """
    entry_type = 'ADDRESS'
    parse_result = parseaddr(entry)
    if not '@' in parse_result[1]:
        entry_type = 'DOMAIN'

    entry_data = {
        "block_type": "PERM_FAIL",
        "entry_type": entry_type,
        "value": entry
    }

    response = requests.post(
        url,
        headers=headers,
        timeout=MAIL_PIC_RESPONSE_TIMEOUT,
        data = json.dumps(entry_data)
    )
    return response

def unblock_address_by_id(url, block_id, headers):
    """
    Performs a DELETE request to unblock the entry identified by its ID
    """
    response = requests.delete(
        '{0}/{1}'.format(url, block_id),
        headers=headers,
        timeout=MAIL_PIC_RESPONSE_TIMEOUT
    )
    return response

def get_all_blocked_entries(url, headers):
    """
    Returns all currently blocked entries
    """
    response = requests.get(
        url,
        headers=headers,
        timeout=MAIL_PIC_RESPONSE_TIMEOUT
    )
    return response

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = 'Block/unblock senders on outbound')
    parser.add_argument('--region', default = 'eu-west-1', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'the AWS region')
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'DEV3', 'QA', 'PROD','INF'], help = 'the AWS environment')
    parser.add_argument('--get', action='store_true', help = 'retrieve list of currently blacklisted entries')
    parser.add_argument('--block', dest = 'block_entry', help = 'block the provided address or domain')
    parser.add_argument('--unblock-by-id', dest = 'unblock_id', help = 'unblock address by the provided ID')
    args = parser.parse_args()

    pic_fqdn = 'mail-cloudstation-{0}.{1}.hydra.sophos.com'.format(args.region, args.env.lower())
    mail_pic_api_auth = 'xgemail-{0}-mail'.format(args.region)
    connections_bucket = 'cloud-{0}-connections'.format(args.env.lower())

    xgemail_api_url = 'https://{0}/mail/api/xgemail'.format(pic_fqdn)
    blocked_sender_api_url = xgemail_api_url + '/blocked-outbound-sender'

    headers = {
        'Authorization': 'Basic ' + get_passphrase(connections_bucket, mail_pic_api_auth),
        'Content-Type': 'application/json'
    }

    urllib3.disable_warnings(urllib3.exceptions.SecurityWarning)

    if args.get:
        response = get_all_blocked_entries(blocked_sender_api_url, headers)
        if response.ok:
            print json.dumps(response.json(), indent = 4, sort_keys = True)
        else:
            print 'Unable to retrieve all blocked entries. HTTP Response code <{0}>'.format(response.status_code)
    elif args.block_entry:
        response = block_entry(blocked_sender_api_url, args.block_entry, headers)
        if response.ok:
            print 'Successfully blocked entry {0}. ID: {1}'.format(
                args.block_entry,
                response.json()['id']
            )
        else:
            print 'Unable to block entry {0}. HTTP Response code <{1}>'.format(args.block_entry, response.status_code)
    elif args.unblock_id:
        response = unblock_address_by_id(blocked_sender_api_url, args.unblock_id, headers)
        if response.ok:
            print 'Successfully unblocked entry {0}'.format(args.unblock_id)
        else:
            print 'Unable to unblock address with ID {0}. HTTP Response code <{1}>'.format(args.unblock_id, response.status_code)
    else:
        parser.print_help(sys.stderr)
        sys.exit(1)