"""
Description here.

Copyright 2021, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""


import boto3
import logging
import os
from botocore.exceptions import ClientError

print('Loading function')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region = os.environ['AWS_REGION']
account = os.environ['ACCOUNT']
mf_is_security_group = os.environ['MFISSECURITYGROUP']
mf_os_security_group = os.environ['MFOSSECURITYGROUP']

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    try:
        data = ec2.authorize_security_group_ingress(
            GroupId=mf_is_security_groupf,
            IpPermissions=[
                {'IpProtocol': 'tcp',
                 'FromPort': 25,
                 'ToPort': 25,
                 'IpRanges': [{'CidrIp': '73.38.163.251/32'}]},
                {'IpProtocol': 'tcp',
                 'FromPort': 587,
                 'ToPort': 587,
                 'IpRanges': [{'CidrIp': '73.38.163.251/32'}]}
            ])
        print('MF IS Ingress Successfully Set %s' % data)
    except ClientError as e:
        print(e)

    try:
        data = ec2.authorize_security_group_ingress(
            GroupId=mf_os_security_group,
            IpPermissions=[
                {'IpProtocol': 'tcp',
                 'FromPort': 25,
                 'ToPort': 25,
                 'IpRanges': [{'CidrIp': '73.38.163.251/32'}]},
                {'IpProtocol': 'tcp',
                 'FromPort': 587,
                 'ToPort': 587,
                 'IpRanges': [{'CidrIp': '73.38.163.251/32'}]}
            ])
        print('MF OS Ingress Successfully Set %s' % data)
    except ClientError as e:
        print(e)