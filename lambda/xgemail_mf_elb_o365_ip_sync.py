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

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    try:
        data = ec2.authorize_security_group_ingress(
            GroupId='sg-0f9ec72cb03a3cdd8',
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
        print('Ingress Successfully Set %s' % data)
    except ClientError as e:
        print(e)