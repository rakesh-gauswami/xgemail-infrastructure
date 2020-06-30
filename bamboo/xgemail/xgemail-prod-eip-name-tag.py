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
            "18.216.13.105",
            "18.216.13.109",
            "18.216.13.110",
            "18.216.13.200",
            "18.216.23.26",
            "18.216.23.27",
            "18.216.23.56"
        ],
        "internet-xdelivery": [
            "18.216.13.101",
            "18.216.13.103",
            "18.216.13.143",
            "18.216.13.151"
        ],
        "risky-delivery": [
            "18.216.23.9",
            "18.216.23.18",
            "18.216.23.60"
        ],
        "risky-xdelivery": [
            "18.216.23.8",
            "18.216.23.29",
            "18.216.23.50"
        ],
        "delta-delivery": [
            "18.216.13.115",
            "18.216.13.116",
            "18.216.13.144"
        ],
        "delta-xdelivery": [
            "18.216.13.112",
            "18.216.13.113",
            "18.216.13.114"
        ],
        "beta-delivery": [
            "18.216.13.193",
            "18.216.13.194",
            "18.216.13.195"
        ],
        "beta-xdelivery": [
            "18.216.13.196",
            "18.216.13.197",
            "18.216.13.198"
        ],
        "warmup-delivery": [
            "18.216.13.102",
            "18.216.13.104",
            "18.216.13.106"
        ],
        "warmup-xdelivery": [
            "18.216.13.107",
            "18.216.13.108",
            "18.216.13.111"
        ]
    },
    "us-west-2": {
        "internet-delivery": [
            "34.212.96.100",
            "34.212.96.103",
            "34.212.96.107",
            "34.212.96.110",
            "34.212.96.117",
            "34.212.96.119"
        ],
        "internet-xdelivery": [
            "34.212.96.101",
            "34.212.96.102",
            "34.212.96.104"
        ],
        "risky-delivery": [
            "34.213.30.105"
            "34.213.30.106",
            "34.213.30.107"
        ],
        "risky-xdelivery": [
            "34.213.30.40",
            "34.213.30.41",
            "34.213.30.42"
        ],
        "delta-delivery": [
            "34.213.30.31",
            "34.213.30.32",
            "34.213.30.33"
        ],
        "delta-xdelivery": [
            "34.213.30.34",
            "34.213.30.35",
            "34.213.30.36"
        ],
        "beta-delivery": [
            "34.213.30.129",
            "34.213.30.130",
            "34.213.30.131"
        ],
        "beta-xdelivery": [
            "34.213.30.132",
            "34.213.30.133",
            "34.213.30.134"
        ],
        "warmup-delivery": [
            "34.213.30.113",
            "34.213.30.114",
            "34.213.30.115"
        ],
        "warmup-xdelivery": [
            "34.213.30.103",
            "34.213.30.104",
            "34.213.30.110"
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
            "35.159.27.102",
            "35.159.27.143",
            "35.159.27.250"
        ],
        "risky-delivery": [
            "35.159.27.31",
            "35.159.27.32",
            "35.159.27.33"
        ],
        "risky-xdelivery": [
            "35.159.27.10",
            "35.159.27.48",
            "35.159.27.49"
        ],
        "delta-delivery": [
            "35.159.27.121",
            "35.159.27.122",
            "35.159.27.125"
        ],
        "delta-xdelivery": [
            "35.159.27.124",
            "35.159.27.126",
            "35.159.27.144"
        ],
        "beta-delivery": [
            "35.159.27.193",
            "35.159.27.194",
            "35.159.27.195"
        ],
        "beta-xdelivery": [
            "35.159.27.196",
            "35.159.27.197",
            "35.159.27.198"
        ],
        "warmup-delivery": [
            "35.159.27.129",
            "35.159.27.151",
            "35.159.27.153"
        ],
        "warmup-xdelivery": [
            "35.159.27.130",
            "35.159.27.134",
            "35.159.27.152"
        ]
    },
    "eu-west-1": {
        "internet-delivery": [
            "34.253.219.131",
            "34.253.219.134",
            "34.253.238.5",
            "34.253.238.50",
            "34.253.238.55",
            "34.253.238.56"
        ],
        "internet-xdelivery": [
            "34.253.238.40",
            "34.253.238.51",
            "34.253.238.70"
        ],
        "risky-delivery": [
            "34.253.219.129",
            "34.253.219.130",
            "34.253.219.133"
        ],
        "risky-xdelivery": [
            "34.253.219.132",
            "34.253.219.138",
            "34.253.219.161"
        ],
        "delta-delivery": [
            "34.253.238.111",
            "34.253.238.112",
            "34.253.238.113"
        ],
        "delta-xdelivery": [
            "34.253.238.104",
            "34.253.238.105",
            "34.253.238.123"
        ],
        "beta-delivery": [
            "34.253.219.193",
            "34.253.219.194",
            "34.253.219.196"
        ],
        "beta-xdelivery": [
            "34.253.219.198",
            "34.253.219.199",
            "34.253.219.201"
        ],
        "warmup-delivery": [
            "34.253.238.106",
            "34.253.238.109",
            "34.253.238.110"
        ],
        "warmup-xdelivery": [
            "34.253.238.82",
            "34.253.238.83",
            "34.253.238.108"
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
