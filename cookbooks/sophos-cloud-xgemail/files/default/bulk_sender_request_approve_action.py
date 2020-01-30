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

MAIL_PIC_RESPONSE_TIMEOUT = 30

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

def getListFromCsv(args):

    emailList = []
    if args.file:
        file_name = args.file
        with open(file_name, 'r') as csv_file:
            csv_reader = csv.reader(csv_file, delimiter=',')
            for row in csv_reader:
                print row
                emailList.append(row)
    else:
        print 'Aborting... please use any of the following options --approve / --reject / --revoke / --request_approve / --status'
        return None

    return emailList

def call_bulk_sender_request(emailList,args):
    pic_fqdn = 'mail-cloudstation-{0}.{1}.hydra.sophos.com'.format(args.region, args.env.lower())
    mail_pic_api_auth = 'xgemail-{0}-mail'.format(args.region)
    connections_bucket = 'cloud-{0}-connections'.format(args.env.lower())
    mail_pic_api_url = 'https://{0}/mail/api/xgemail'.format(pic_fqdn)

    headers = {
        'Authorization': 'Basic ' + get_passphrase(connections_bucket, mail_pic_api_auth),
        'Content-Type': 'application/json'
    }

    for emailAddress in emailList:
        for email  in emailAddress:
            bulk_sender_request_approved_url = mail_pic_api_url + '/bulksender/request-approved'
            url = bulk_sender_request_approved_url + '?emailAddress={0}'.format(email)
            urllib3.disable_warnings(urllib3.exceptions.SecurityWarning)
            response = requests.post(
                url,
                headers = headers,
                timeout = MAIL_PIC_RESPONSE_TIMEOUT,
            )

    if response.ok:
        print 'Successfully submitted {0} request, response: {1}'.format('request-approved' , response)
    else:
        print 'There was a problem in submitting {0} request, response code {1}'.format('request-approved', response.status_code)
        return None

    return response

if __name__ == '__main__':
    try:
        arg_parser = argparse.ArgumentParser(description = 'Request_Approve Bulk Sender Request')
        parsed_args = get_parsed_args(arg_parser)

        emailList = getListFromCsv(parsed_args)

        result = call_bulk_sender_request(emailList,parsed_args)
        if result is None or not result:
            arg_parser.print_help(sys.stderr)
            sys.exit(1)

    except Exception as e:
        print 'An Exception occurred in main <{0}>'.format(e)
        sys.exit(1)
