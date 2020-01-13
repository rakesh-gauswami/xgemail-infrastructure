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

MAIL_PIC_RESPONSE_TIMEOUT = 30

def get_parsed_args(parser):
    parser.add_argument('--region', default = 'eu-west-1', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'AWS region', required = True)
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'DEV3', 'QA', 'PROD','INF'], help = 'AWS environment', required = True)
    parser.add_argument('--customerid', help = 'Customer ID of the bulk sender request sender', required = True)
    parser.add_argument('--emailid', help = 'Email address of the bulk sender request mailbox', required = True)
    parser.add_argument('--approve', action = 'store_true', help = 'Approve the bulk sender request')
    parser.add_argument('--reject', action = 'store_true', help = 'Reject the bulk sender request')
    parser.add_argument('--revoke', actiom = 'store_true', help = 'Revoke the bulk sender request, removes all relevant documents from S3')
    args = parser.parse_args()
    return args

def get_passphrase(bucket, mail_pic_auth):
    s3 = boto3.client('s3')
    passphrase = s3.get_object(Bucket = bucket, Key = mail_pic_auth)
    return base64.b64encode('mail:' + passphrase['Body'].read())

def create_mail_pic_request_data(args):
    pic_fqdn = 'mail-cloudstation-{0}.{1}.hydra.sophos.com'.format(args.region, args.env.lower())
    mail_pic_api_auth = 'xgemail-{0}-mail'.format(args.region)
    connections_bucket = 'cloud-{0}-connections'.format(args.env.lower())
    mail_pic_api_url = 'https://{0}/mail/api/xgemail'.format(pic_fqdn)
    data = []

    if args.approve:
        bulk_sender_api_url = mail_pic_api_url + '/bulksender/approve'
        data.append('approve')
    elif args.reject:
        bulk_sender_api_url = mail_pic_api_request_data + '/bulksender/reject'
        data.append('reject')
    elif args.revoke:
        bulk_sender_api_url = mail_pic_api_url + '/bulksender/revoke'
        data.append('revoke')
    else:
        print 'Aborting... please use any of the following options --approve / --reject / --revoke'
        return None

    headers = {
        'Authorization': 'Basic ' + get_passphrase(connections_bucket, mail_pic_api_auth),
        'Content-Type': 'application/json'
    }

    body = {
        'customerId': args.customerid,
        'emailAddress': args.emailid
    }

    data.append(bulk_sender_api_url)
    data.append(headers)
    data.append(body)

    return data


def post_mail_pic_request(mail_pic_api_data):
    urllib3.disable_warnings(urllib3.exceptions.SecurityWarning)

    response = requests.post(
        mail_pic_api_data[1],
        headers = mail_pic_api_data[2],
        timeout = MAIL_PIC_RESPONSE_TIMEOUT,
        data = mail_pic_api_data[3]
    )

    if response.ok:
        print 'Successfully submitted {0} request, response: {1}'.format(mail_pic_api_data[0], response.json())
    else:
        print 'There was a problem in submitting {0} request, response code {1}'.format(mail_pic_api_data[0], response.status_code)
        return None

    return response

if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(description = 'Approve/Reject/Revoke Bulk Sender Request')
    parsed_args = get_parsed_args(arg_parser)

    mail_pic_api_request_data = create_mail_pic_request_data(parsed_args)
    if mail_pic_api_request_data is None or not mail_pic_api_request_data:
        arg_parser.print_help(sys.stderr)
        sys.exit(1)

    post_response = post_mail_pic_request(mail_pic_api_request_data)
    if post_response is None or not post_response:
        arg_parser.print_help(sys.stderr)
        sys.exit(1)
