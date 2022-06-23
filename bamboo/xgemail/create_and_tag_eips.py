#!/usr/bin/env python
import argparse
import boto3
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

session = boto3.session.Session(profile_name='eml100gru', region_name='sa-east-1')
ec2 = session.resource('ec2')
ec2_client = session.client('ec2')
#ec2_client = boto3.client('ec2', region_name='eu-central-1')
""":type: pyboto3.ec2 """


def tag_eip(allocation_id):
    ec2_client.create_tags(
            Resources=[allocation_id],
            Tags=[
                {
                    'Key': 'Name',
                    'Value': args.instance
                },
                {
                    'Key': 'blacklist',
                    'Value': '0'
                },
                {
                    'Key': 'last_reputation_checked',
                    'Value': '2020-01-31 07:25:03.155328'
                },
                {
                    'Key': 'last_month_volume',
                    'Value': '3.4'
                },
                {
                    'Key': 'last_day_volume',
                    'Value': '3.42'
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
                    'Key': 'detached',
                    'Value': datetime.now().strftime('%Y%m%d%H%M%S')
                }
            ]
        )


# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(
        description='Create EIP and add specified Tags.')
    #parser.add_argument('--account', '-a', dest='account', default='inf', required=True, help='The account you are working in.')
    #parser.add_argument('--region', '-r', dest='region', default='eu-west-1', required=True, help='The region you are working in.')
    parser.add_argument('--instance', '-i', dest='instance', required=True, help='The region you are working in.')
    return parser.parse_args()


if __name__ == '__main__':

    args = parse_command_line()
    for x in range(1):
        eip = ec2_client.allocate_address(Domain='vpc')
        print("Public Ip: {0}".format(eip['PublicIp']))
        print("Allocation Id: {0}".format(eip['AllocationId']))
        tag_eip(eip['AllocationId'])
