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

us-east-2
18.216.13.64/26 (18.216.13.65 - 18.216.13.126)       - internet-delivery | internet-xdelivery  |  delta-delivery  |   warmup-delivery
18.216.23.0/26 (18.216.23.1 - 18.216.23.62)          - risky-delivery    |   risky-xdelivery   |
18.216.13.128/26 (18.216.13.129 - 18.216.13.190)     - internet-delivery | internet-xdelivery  |  delta-delivery  |   warmup-delivery
18.216.13.192/26 (18.216.13.193 - 18.216.13.254)     - bulk

us-west-2
34.212.96.64/26 (34.212.96.65 - 34.212.96.126)       - internet-delivery | internet-xdelivery  |  delta-delivery  |   warmup-delivery
34.213.30.0/26 (34.213.30.1 - 34.213.30.62)          - risky-delivery    |   risky-xdelivery   |
34.213.30.64/26 (34.213.30.65 - 34.213.30.126)       - internet-delivery | internet-xdelivery  |  delta-delivery  |   warmup-delivery
34.213.30.128/26 (34.213.30.129 - 34.213.30.190)     - bulk

eu-central-1
35.159.27.64/26 (35.159.27.65 - 35.159.27.126)       - internet-delivery | internet-xdelivery  |  delta-delivery  |   warmup-delivery
35.159.27.0/26 (35.159.27.1 - 35.159.27.62)          - risky-delivery    |   risky-xdelivery   |
35.159.27.128/26 (35.159.27.129 - 35.159.27.190)     - internet-delivery | internet-xdelivery  |  delta-delivery  |   warmup-delivery
35.159.27.192/26 (35.159.27.193 - 35.159.27.254)     - bulk

eu-west-1
34.253.238.0/26 (34.253.238.1 - 34.253.238.62)       - internet-delivery | internet-xdelivery  |  delta-delivery  |   warmup-delivery
34.253.219.128/26 (34.253.219.129 - 34.253.219.190)  - risky-delivery    |   risky-xdelivery
34.253.238.64/26 (34.253.238.65 - 34.253.238.126)    - internet-delivery | internet-xdelivery  |  delta-delivery  |   warmup-delivery
34.253.219.192/26 (34.253.219.193 - 34.253.219.254)  - bulk

"""

import boto3
import ipaddress
import argparse
import os
import time
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

aws_access_key_id = os.environ['bamboo_custom_aws_accessKeyId']
aws_secret_access_key = os.environ['bamboo_custom_aws_secretAccessKey_password']
aws_session_token = os.environ['bamboo_custom_aws_sessionToken_password']
region = os.environ['REGION']
session = boto3.Session(aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key, aws_session_token=aws_session_token, region_name=region)
ec2_client = session.client('ec2')
""":type: pyboto3.ec2 """

eips = {
    "us-east-2": {
        "internet-delivery": [
            "18.216.13.101",
            "18.216.13.103",
            "18.216.13.105",
            "18.216.13.109",
            "18.216.13.110",
            "18.216.13.117",
            "18.216.13.200"
        ],
        "internet-xdelivery": [
            "18.216.23.21",
            "18.216.23.22",
            "18.216.23.29",
            "18.216.23.30"
        ],
        "risky-delivery": [
            "18.216.13.170",
            "18.216.13.171",
            "18.216.13.172"
        ],
        "risky-xdelivery": [
            "18.216.13.211",
            "18.216.13.212",
            "18.216.13.213"
        ],
        "delta-delivery": [
            "18.216.23.41",
            "18.216.23.42",
            "18.216.23.43",
            "18.216.23.44",
            "18.216.23.45",
            "18.216.23.46"
        ],
        "delta-xdelivery": [

        ],
        "beta-delivery": [

        ],
        "beta-xdelivery": [

        ],
        "warmup-delivery": [
            "18.216.13.112",
            "18.216.13.113",
            "18.216.13.114",
            "18.216.13.115",
            "18.216.13.116",
            "18.216.13.118"
        ],
        "warmup-xdelivery": [

        ]
    },
    "us-west-2": {
        "internet-delivery": [
            "34.212.96.103",
            "34.212.96.107",
            "34.212.96.100",
            "34.212.96.110",
            "34.212.96.117",
            "34.212.96.119"
        ],
        "internet-xdelivery": [
            "34.213.30.10",
            "34.213.30.11",
            "34.213.30.12"
        ],
        "risky-delivery": [
            "34.213.30.105"
            "34.213.30.106",
            "34.213.30.107"
        ],
        "risky-xdelivery": [
            "34.213.30.141",
            "34.213.30.142",
            "34.213.30.143"
        ],
        "delta-delivery": [
            "34.213.30.31",
            "34.213.30.32",
            "34.213.30.33",
            "34.213.30.34",
            "34.213.30.35",
            "34.213.30.36"
        ],
        "delta-xdelivery": [

        ],
        "beta-delivery": [

        ],
        "beta-xdelivery": [

        ],
        "warmup-delivery": [
            "34.212.96.114",
            "34.212.96.115",
            "34.212.96.116",
            "34.212.96.118",
            "34.212.96.120",
            "34.212.96.121"
        ],
        "warmup-xdelivery": [

        ]
    },
    "eu-central-1": {
        "internet-delivery": [
            "35.159.27.103",
            "35.159.27.104",
            "35.159.27.105",
            "35.159.27.107",
            "35.159.27.106",
            "35.159.27.142"
        ],
        "internet-xdelivery": [
            "35.159.27.11",
            "35.159.27.12",
            "35.159.27.13"
        ],
        "risky-delivery": [
            "35.159.27.113",
            "35.159.27.116",
            "35.159.27.118"
        ],
        "risky-xdelivery": [
            "35.159.27.193",
            "35.159.27.194",
            "35.159.27.195"
        ],
        "delta-delivery": [
            "35.159.27.193",
            "35.159.27.194",
            "35.159.27.195",
            "35.159.27.196",
            "35.159.27.197",
            "35.159.27.198"
        ],
        "delta-xdelivery": [

        ],
        "beta-delivery": [

        ],
        "beta-xdelivery": [

        ],
        "warmup-delivery": [
            "35.159.27.121",
            "35.159.27.122",
            "35.159.27.123",
            "35.159.27.124",
            "35.159.27.125",
            "35.159.27.126"
        ],
        "warmup-xdelivery": [

        ]
    },
    "eu-west-1": {
        "internet-delivery": [
            "34.253.238.5",
            "34.253.238.50",
            "34.253.238.51",
            "34.253.238.55",
            "34.253.238.56",
            "34.253.238.70"
        ],
        "internet-xdelivery": [
            "34.253.238.111",
            "34.253.238.112",
            "34.253.238.113"
        ],
        "risky-delivery": [
            "34.253.219.177",
            "34.253.219.178",
            "34.253.219.179"
        ],
        "risky-xdelivery": [
            "34.253.219.193",
            "34.253.219.194",
            "34.253.219.195"
        ],
        "delta-delivery": [
            "34.253.219.81",
            "34.253.219.82",
            "34.253.219.83",
            "34.253.219.84",
            "34.253.219.85",
            "34.253.219.86"
        ],
        "delta-xdelivery": [

        ],
        "beta-delivery": [

        ],
        "beta-xdelivery": [

        ],
        "warmup-delivery": [
            "34.253.219.81",
            "34.253.219.82",
            "34.253.219.83",
            "34.253.219.84",
            "34.253.219.85",
            "34.253.219.86"
        ],
        "warmup-xdelivery": [

        ]
    }
}

def get_eip(ip):
    """
    Lookup EIP from the provided IP.
    """
    eip = ec2_client.describe_addresses(
        PublicIps=[ip]
    )['Addresses'][0]
    return eip


def tag_eip(instance, allocation_id):
    """
    Tag EIP with the provided Name.
    """
    ec2_client.create_tags(
            Resources=[allocation_id],
            Tags=[
                {
                    'Key': 'Name',
                    'Value': instance
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

    return parser.parse_args()


if __name__ == '__main__':

    args = parse_command_line()

    if args.account == 'prod':
        for instance, ip_list in eips[args.region].items():
            for ip in ip_list:
                print instance, ip
                tag_eip(
                    instance=instance,
                    allocation_id=get_eip(ip)['AllocationId']
                )
                time.sleep(1)

    else:
        print "Not prod. Skipping %s account" % args.account
