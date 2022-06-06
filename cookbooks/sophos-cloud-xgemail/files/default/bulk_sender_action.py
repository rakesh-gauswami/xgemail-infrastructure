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
import json

MAIL_PIC_RESPONSE_TIMEOUT = 30

def get_parsed_args(parser):
    parser.add_argument('--region', default = 'eu-west-1', choices=['us-east-2', 'eu-west-1', 'eu-central-1', 'ca-central-1', 'ap-northeast-1', 'ap-southeast-2', 'ap-south-1', 'sa-east-1'], help = 'AWS region', required = True)
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'DEV3', 'QA', 'PROD','INF', 'eml000cmh', 'eml010yul', 'eml030bom', 'eml030gru', 'eml030hnd', 'eml030syd', 'eml030yul', 'eml100bom', 'eml100gru', 'eml100hnd', 'eml100syd', 'eml100yul'], help = 'AWS environment', required = True)
    parser.add_argument('--customerid', help = 'Customer ID of the bulk sender request sender', required = False)
    parser.add_argument('--emailid', help = 'Email address of the bulk sender request mailbox', required = True)
    parser.add_argument('--approve', action = 'store_true', help = 'Approve the bulk sender request')
    parser.add_argument('--reject', action = 'store_true', help = 'Reject the bulk sender request')
    parser.add_argument('--request_approve', action = 'store_true', help = 'Request the bulk sender and approved the request')
    parser.add_argument('--revoke', action = 'store_true', help = 'Revoke the bulk sender request, removes all relevant documents from S3')
    parser.add_argument('--status', action = 'store_true', help = 'Returns current bulk sender request status')
    args = parser.parse_args()
    return args

def get_passphrase(bucket, mail_pic_auth):
    s3 = boto3.client('s3')
    passphrase = s3.get_object(Bucket = bucket, Key = mail_pic_auth)
    return base64.b64encode('mail:' + passphrase['Body'].read())

def create_mail_pic_request_data(args):
    if args.env.startswith('eml'):
        pic_fqdn = 'mail.{}.ctr.sophos.com'.format(args.env.replace('eml', 'stn'))
    else:
        pic_fqdn = 'mail-cloudstation-{0}.{1}.hydra.sophos.com'.format(args.region, args.env.lower())

    mail_pic_api_auth = 'xgemail-{0}-mail'.format(args.region)
    connections_bucket = 'cloud-{0}-connections'.format(args.env.lower())
    mail_pic_api_url = 'https://{0}/mail/api/xgemail'.format(pic_fqdn)
    data = []

    if args.approve:
        bulk_sender_api_url = mail_pic_api_url + '/bulksender/approve'
        data.append('approve')
    elif args.reject:
        bulk_sender_api_url = mail_pic_api_url + '/bulksender/reject'
        data.append('reject')
    elif args.revoke:
        bulk_sender_api_url = mail_pic_api_url + '/bulksender/revoke'
        data.append('revoke')
    elif args.request_approve:
        bulk_sender_api_url = ''
        bulk_sender_request_approved_url = mail_pic_api_url + '/bulksender/request-approved'
        data.append('request_approve')
    elif args.status:
        bulk_sender_api_url = mail_pic_api_url + '/bulksender/status'
        data.append('status')
    else:
        print('Aborting... please use any of the following options --approve / --reject / --revoke / --request_approve / --status')
        return None

    if bulk_sender_api_url:
        url = bulk_sender_api_url + '?customerId={0}&emailAddress={1}'.format(args.customerid, args.emailid)
    else:
        url = bulk_sender_request_approved_url + '?emailAddress={0}'.format(args.emailid)

    headers = {
        'Authorization': 'Basic ' + get_passphrase(connections_bucket, mail_pic_api_auth),
        'Content-Type': 'application/json'
    }

    data.append(url)
    data.append(headers)

    return data


def post_mail_pic_request(mail_pic_api_data):
    urllib3.disable_warnings(urllib3.exceptions.SecurityWarning)

    response = requests.post(
        mail_pic_api_data[1],
        headers = mail_pic_api_data[2],
        timeout = MAIL_PIC_RESPONSE_TIMEOUT,
    )

    if response.ok:
        print('Successfully submitted {0} request, response: {1}'.format(mail_pic_api_data[0], response))
    else:
        print('There was a problem in submitting {0} request, response code {1}'.format(mail_pic_api_data[0], response.status_code))
        return None

    return response

def perform_get_request(get_mail_pic_data):
    urllib3.disable_warnings(urllib3.exceptions.SecurityWarning)

    mail_pic_response = requests.get(
        get_mail_pic_data[1],
        headers = get_mail_pic_data[2],
        timeout = MAIL_PIC_RESPONSE_TIMEOUT
    )

    if mail_pic_response.ok:
        print(json.dumps(mail_pic_response.json(), indent = 4))
    else:
        print('Unable to retrieve the bulk sender status. HTTP Response code <{0}>'.format(mail_pic_response.status_code))
        return None

    return mail_pic_response

if __name__ == '__main__':
    try:
        arg_parser = argparse.ArgumentParser(description = 'Approve/Reject/Revoke/Request_Approve Bulk Sender Request')
        parsed_args = get_parsed_args(arg_parser)

        mail_pic_api_request_data = create_mail_pic_request_data(parsed_args)
        if mail_pic_api_request_data is None or not mail_pic_api_request_data:
            arg_parser.print_help(sys.stderr)
            sys.exit(1)

        if parsed_args.status:
            get_response = perform_get_request(mail_pic_api_request_data)
            if get_response is None or not get_response:
                sys.exit(1)
        else:
            post_response = post_mail_pic_request(mail_pic_api_request_data)
            if post_response is None or not post_response:
                sys.exit(1)
    except Exception as e:
        print('An Exception occurred in main <{0}>'.format(e))
        sys.exit(1)

