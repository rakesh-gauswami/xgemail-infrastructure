"""
Description here.

Copyright 2021, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import http.client
import uuid
import sys
import boto3
import logging
import json
import re
import os
from botocore.exceptions import ClientError

print('Loading MF ELB O365 IP Sync function')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region = os.environ['AWS_REGION']
account = os.environ['ACCOUNT']
mf_security_groups = [os.environ['MFISSECURITYGROUP'], os.environ['MFOSSECURITYGROUP']]

ec2 = boto3.client('ec2')

def o365_api_call(sg):
    """
    Query the Office 365 IP Address web service to retrieve all IP addresses used by Microsoft for sending email.
    """
    logger.info("Setting ingress rules for MF-IS and MF-OS ELB Security Groups.")

    # Microsoft Web Service URLs
    o365_ips = []
    url_ms_o365_endpoints = "endpoints.office.com"
    uri_ms_o365_endpoints = "/endpoints/Worldwide?ServiceAreas=Exchange&ClientRequestId="
    guid = str(uuid.uuid4())
    request_string = uri_ms_o365_endpoints + guid
    conn = http.client.HTTPSConnection(url_ms_o365_endpoints)
    conn.request('GET', request_string)
    res = conn.getresponse()

    if not res.status == 200:
        logger.info("ENDPOINTS request to MS web service failed. Aborting operation.")
        sys.exit(0)
    else:
        logger.info("ENDPOINTS request to MS web service was successful.")
        dict_o365_all = json.loads(res.read())

    # Process for each record(id) of the endpoint JSON data
    for dict_o365_record in dict_o365_all:
        if 'ips' in dict_o365_record:
            list_ips = list(dict_o365_record['ips'])
            for ip in list_ips:
                if not re.match('^.+:', ip):
                    o365_ips.append(ip)

    num_o365_ips = len(o365_ips)
    logger.info("Number of ENDPOINTS to import : IPv4 host/net:" + str(num_o365_ips))
    clear_ingress_rules(sg)

    return o365_ips

def clear_ingress_rules(sg):
    """
    Remove all existing ingress rules from security group to avoid abandoned ipranges or duplicate errors
    """
    logger.info("Clearing all ingress rules for Security Groups before importing...")
    try:
        data = ec2.describe_security_groups(
            GroupIds=[sg]
        )
        clear_ip_list = data['SecurityGroups'][0]['IpPermissions']
        print(clear_ip_list)
    except ClientError as e:
        print(e)

    try:
        data = ec2.revoke_security_group_ingress(
            GroupId=sg,
            IpPermissions=clear_ip_list)
        print('MF Ingress Successfully REVOKED for {}'.format(sg))
    except ClientError as e:
        print(e)

def set_ingress_rules(ip, sg):
    """
    Set ingress rules on both MF-IS and MF-OS ELB SGs to allow all O365 published IPs to connect.
    """
    logger.info("Setting ingress rules for MF-IS and MF-OS ELB Security Groups.")
    try:
        data = ec2.authorize_security_group_ingress(
            GroupId=sg,
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
        print('MF Ingress Rules Successfully Set for {}'.format(sg))
    except ClientError as e:
        print(e)

def mf_elb_o365_ip_sync_handler(event, context):
    logger.info("got event {0}".format(event))
    logger.info("Received event: {0}".format(json.dumps(event)))
    logger.info("Log stream name: {0}".format(context.log_stream_name))
    logger.info("Log group name: {0}".format(context.log_group_name))
    logger.info("Request ID: {0}".format(context.aws_request_id))
    logger.info("Mem. limits(MB): {0}".format(context.memory_limit_in_mb))

    for sg in mf_security_groups:
        for ip in o365_api_call(sg=sg):
            set_ingress_rules(ip=ip, sg=sg)

    logger.info("===FINISHED=== MF ELB O365 IP Sync.")
