#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2020, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import argparse
import base64
import boto3
import requests
import sys
import urllib3
import csv
import pip

MAIL_PIC_RESPONSE_TIMEOUT = 30
ERROR_ENTRIES_PATH = '/tmp/bulk-sender-errors.txt'

try:
    from prettytable import PrettyTable
except ImportError:
    pip.main(['install', 'PrettyTable'])
    from prettytable import PrettyTable

def get_parsed_args(parser):
    parser.add_argument('--region', default = 'eu-west-1', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'AWS region', required = True)
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'DEV3', 'QA', 'PROD','INF'], help = 'AWS environment', required = True)
    parser.add_argument('--file', help = 'Pass a csv or text with comma separate  mail boxes ', required = True)
    args = parser.parse_args()
    return args

def get_passphrase(bucket, mail_pic_auth):
    s3 = boto3.client('s3')
    passphrase = s3.get_object(Bucket = bucket, Key = mail_pic_auth)
    return base64.b64encode('mail:' + passphrase['Body'].read())

def get_mail_box_list_from_file(args):

    mailboxList = []
    if args.file:
        file_name = args.file
        with open(file_name, 'r') as csv_file:
            csv_reader = csv.reader(csv_file)
            for row in csv_reader:
                for r in row:
                        new_row = r.strip()
                        mailboxList.append(new_row)
    else:
        print 'Aborting... please use -- file { .csv file }'
        return None

    return mailboxList

def call_bulk_sender_request_api(mailBoxList,args):
    pic_fqdn = 'mail-cloudstation-{0}.{1}.hydra.sophos.com'.format(args.region, args.env.lower())
    mail_pic_api_auth = 'xgemail-{0}-mail'.format(args.region)
    connections_bucket = 'cloud-{0}-connections'.format(args.env.lower())
    mail_pic_api_url = 'https://{0}/mail/api/xgemail'.format(pic_fqdn)

    headers = {
        'Authorization': 'Basic ' + get_passphrase(connections_bucket, mail_pic_api_auth),
        'Content-Type': 'application/json'
    }

    failed_result = []
    for mailbox  in mailBoxList:
            bulk_sender_request_approved_url = mail_pic_api_url + '/bulksender/request-approved'
            url = bulk_sender_request_approved_url + '?emailAddress={0}'.format(mailbox)
            urllib3.disable_warnings(urllib3.exceptions.SecurityWarning)
            response = requests.post(
                url,
                headers = headers,
                timeout = MAIL_PIC_RESPONSE_TIMEOUT,
            )
            if response.ok:
                ''
            else:
                failed_result.append(mailbox)

    if len(failed_result) == 0:
        print 'Successfully submitted {0} request, response: {1}'.format('request-approved' , response)
    else:
        print 'The list of mail boxes that not successfully submitted can be found in /tmp/bulk-sender-errors.txt '
        write_error_file(failed_result)

    return response

def write_error_file(failed_result):

    t = PrettyTable(['Mail boxes '])
    t.align = 'l'

    for cur_entry in failed_result:
            t.add_row([cur_entry])

    with open(ERROR_ENTRIES_PATH, 'w') as write_file:
        write_file.write(t.get_string())

if __name__ == '__main__':
    try:
        arg_parser = argparse.ArgumentParser(description = 'Request_Approve Bulk Sender Request')
        parsed_args = get_parsed_args(arg_parser)

        mailBoxList = get_mail_box_list_from_file(parsed_args)

        result = call_bulk_sender_request_api(mailBoxList,parsed_args)

        if result is None or not result:
            arg_parser.print_help(sys.stderr)
            sys.exit(1)

    except Exception as e:
        print 'An Exception occurred in main <{0}>'.format(e)
        sys.exit(1)
