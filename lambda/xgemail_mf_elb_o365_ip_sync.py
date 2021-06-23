"""
Description here.

Copyright 2021, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""



import uuid
import sys
import boto3
import logging
import json
import re
import requests
import os
from botocore.exceptions import ClientError


print('Loading MF ELB O365 IP Sync function')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region = os.environ['AWS_REGION']
account = os.environ['ACCOUNT']
mf_is_security_group = os.environ['MFISSECURITYGROUP']
mf_os_security_group = os.environ['MFOSSECURITYGROUP']

ec2 = boto3.client('ec2')

def o365_api_call():
    """
    Query the Office 365 IP Address web service to retrieve all IP addresses used by Microsoft for sending email.
    """
    logger.info("Setting ingress rules for MF-IS and MF-OS ELB Security Groups.")

    # Microsoft Web Service URLs
    o365_ips = []
    url_ms_o365_endpoints = "https://endpoints.office.com/endpoints/Worldwide?ServiceAreas=Exchange&ClientRequestId="
    guid = str(uuid.uuid4())
    url = url_ms_o365_endpoints + guid
    res = requests.get(url=url)

    if not res.status == 200:
        log(1, "ENDPOINTS request to MS web service failed. Aborting operation.")
        sys.exit(0)
    else:
        log(2, "ENDPOINTS request to MS web service was successful.")
        dict_o365_all = json.loads(res.read())

    # Process for each record(id) of the endpoint JSON data
    for dict_o365_record in dict_o365_all:
        if dict_o365_record.has_key('ips'):
            list_ips = list(dict_o365_record['ips'])
            for ip in list_ips:
                if not re.match('^.+:', ip):
                    o365_ips.append(ip)

    num_o365_ips = len(o365_ips)
    logger.info(1, "Number of ENDPOINTS to import : IPv4 host/net:" + str(num_o365_ips))

    return o365_ips

def set_ingress_rules(ip):
    """
    Set ingress rules on both MF-IS and MF-OS ELB SGs to allow all O365 published IPs to connect.
    """
    logger.info("Setting ingress rules for MF-IS and MF-OS ELB Security Groups.")
    try:
        data = ec2.authorize_security_group_ingress(
            GroupId=mf_is_security_group,
            IpPermissions=[
                {'IpProtocol': 'tcp',
                 'FromPort': 25,
                 'ToPort': 25,
                 'IpRanges': [{'CidrIp': ip}]},
                {'IpProtocol': 'tcp',
                 'FromPort': 587,
                 'ToPort': 587,
                 'IpRanges': [{'CidrIp': ip}]}
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
                 'IpRanges': [{'CidrIp': ip}]},
                {'IpProtocol': 'tcp',
                 'FromPort': 587,
                 'ToPort': 587,
                 'IpRanges': [{'CidrIp': ip}]}
            ])
        print('MF OS Ingress Successfully Set %s' % data)
    except ClientError as e:
        print(e)


def mf_elb_o365_ip_sync_handler(event, context):
    logger.info("got event {}".format(event))
    logger.info("Received event: {}".format(json.dumps(event)))
    logger.info("Log stream name: {}".format(context.log_stream_name))
    logger.info("Log group name: {}".format(context.log_group_name))
    logger.info("Request ID: {}".format(context.aws_request_id))
    logger.info("Mem. limits(MB): {}".format(context.memory_limit_in_mb))

    for ip in o365_api_call():
        set_ingress_rules(ip=ip)

    logger.info("===FINISHED=== MF ELB O365 IP Sync.")
