#!/usr/bin/env python
import boto3
from datetime import datetime

session = boto3.session.Session(profile_name='eml100gru', region_name='sa-east-1')
ec2 = session.resource('ec2')
ec2_client = session.client('ec2')
""":type: pyboto3.ec2 """


def get_eips():
    return ec2_client.describe_addresses(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': [
                    '*delivery',
                ]
            },
        ],
    )['Addresses']

def tag_eip(allocation_id):
    ec2_client.create_tags(
            Resources=[allocation_id],
            Tags=[
                {
                    'Key': 'blacklist',
                    'Value': '0'
                },
                {
                    'Key': 'last_reputation_checked',
                    'Value': '2022-05-01 07:25:03.155328'
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


if __name__ == '__main__':

    for x in range(1):
        for eip in get_eips():
            print("Adding tags to EIP {0}".format(eip['PublicIp']))
            tag_eip(eip['AllocationId'])
