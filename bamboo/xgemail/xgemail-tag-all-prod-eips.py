#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
"""
us-west-2

34.212.96.64/26 (34.212.96.65 - 34.212.96.126)
34.213.30.0/26 (34.213.30.1 - 34.213.30.62)
34.213.30.64/26 (34.213.30.65 - 34.213.30.126)
34.213.30.128/26 (34.213.30.129 - 34.213.30.190)
198.154.181.0/24

eu-west-1
34.253.219.128/26 (34.253.219.129 - 34.253.219.190)
34.253.219.192/26 (34.253.219.193 - 34.253.219.254)
34.253.238.0/26 (34.253.238.1 - 34.253.238.62)
34.253.238.64/26 (34.253.238.65 - 34.253.238.126)
198.154.180.0/24

eu-central-1
35.159.27.0/26 (35.159.27.1 - 35.159.27.62)
35.159.27.64/26 (35.159.27.65 - 35.159.27.126)
35.159.27.128/26 (35.159.27.129 - 35.159.27.190)
35.159.27.192/26 (35.159.27.193 - 35.159.27.254)
94.140.18.0/24

us-east-2
18.216.13.64/26 (18.216.13.65 - 18.216.13.126)
18.216.13.128/26 (18.216.13.129 - 18.216.13.190)
18.216.13.192/26 (18.216.13.193 - 18.216.13.254)
18.216.23.0/26 (18.216.23.1 - 18.216.23.62)
103.246.251.0/24

"""

import boto3
import ipaddress
import argparse
import os
import time
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

aws_access_key_id = os.environ['AWS_ACCESS_KEY_ID']
aws_secret_access_key = os.environ['AWS_SECRET_ACCESS_KEY']
aws_session_token = os.environ['AWS_SESSION_TOKEN']


def get_eips(iplist):
    """
    Lookup all EIPs in the provided list of IPs
    """
    print("Looking up current EIPs.")
    eips = ec2_client.describe_addresses(
        PublicIps=iplist
    )['Addresses']
    return eips


def tag_eip(allocation_id):
    ec2_client.create_tags(
            Resources=[allocation_id],
            Tags=[
                {
                    'Key': 'blacklist',
                    'Value': '0'
                },
                {
                    'Key': 'detached',
                    'Value': datetime.now().strftime('%Y%m%d%H%M%S')
                },
                {
                    'Key': 'last_day_volume',
                    'Value': '0'
                },
                {
                    'Key': 'last_month_volume',
                    'Value': '0'
                },
                {
                    'Key': 'last_reputation_checked',
                    'Value': '0'
                },
                {
                    'Key': 'snds_score',
                    'Value': 'C-UNKNOWN'
                },
                {
                    'Key': 'talos_score',
                    'Value': 'B-Neutral'
                },
                {
                    'Key': 'Project',
                    'Value': 'xgemail'
                },
                {
                    'Key': 'BusinessUnit',
                    'Value': 'MSG'
                },
                {
                    'Key': 'Application',
                    'Value': 'cloudemail'
                },
                {
                    'Key': 'OwnerEmail',
                    'Value': 'sophosmailops@sophos.com'
                }
            ]
        )


# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(
        description='Add specified Tags to all CloudEmail Public Elastic IP Addresses.')
    parser.add_argument('--account', '-a', dest='account', default='prod', choices=[
        'inf', 'dev', 'dev3', 'qa', 'prod'], help='The account you are working in.')
    parser.add_argument('--region', '-r', dest='region', default='eu-central-1', choices=[
        'eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help='The region you are working in.')
    parser.add_argument('--profile', '-p', dest='profile', default=None, help='The AWS credentials profile.')

    return parser.parse_args()


if __name__ == '__main__':

    args = parse_command_line()

    if args.account == 'prod':
        if args.region == 'us-west-2':
            #blocks = ['34.212.96.64/26', '34.213.30.0/26', '34.213.30.64/26', '34.213.30.128/26', '198.154.181.0/24']
            blocks = ['198.154.181.0/24']
        if args.region == 'eu-west-1':
            #blocks = ['34.253.219.128/26', '34.253.219.192/26', '34.253.238.0/26', '34.253.238.64/26', '198.154.180.0/24']
            blocks = ['198.154.180.0/24']
        if args.region == 'eu-central-1':
            #blocks = ['35.159.27.0/26', '35.159.27.64/26', '35.159.27.128/26', '35.159.27.192/26', '94.140.18.0/24']
            blocks = ['94.140.18.0/24']
        if args.region == 'us-east-2':
            #blocks = ['18.216.13.64/26', '18.216.13.128/26', '18.216.13.192/26', '18.216.23.0/26', '103.246.251.0/24']
            blocks = ['103.246.251.0/24']

        ip_list = []
        for block in blocks:
            ip_net = ipaddress.ip_network(unicode(block))
            for host in ip_net.hosts():
                ip_list.append(str(host))

        if args.profile is not None:
            session = boto3.Session(profile_name=args.profile, region_name=args.region)
        else:
            session = boto3.Session(aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key, aws_session_token=aws_session_token, region_name=args.region)

        ec2_client = session.client('ec2')
        """:type: pyboto3.ec2 """

        for eip in get_eips(ip_list):
            tag_eip(eip['AllocationId'])
            time.sleep(1)

    else:
        print "Not prod. Skipping %s account" % args.account
