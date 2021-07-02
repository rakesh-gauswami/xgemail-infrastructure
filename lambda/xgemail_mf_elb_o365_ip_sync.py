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
global o365_ips


def o365_api_call():
    """
    Query the Office 365 IP Address web service to retrieve all IP addresses used by Microsoft for sending email.
    """
    logger.info("Setting ingress rules for MF-IS and MF-OS ELB Security Groups.")

    # Microsoft Web Service URLs
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
    o365_ips.sort()
    num_o365_ips = len(o365_ips)
    logger.info("Number of Office365 IPs to import : IPv4 host/net:" + str(num_o365_ips))


def retrieve_existing_ingress_rules(sg):
    """
    Retrieve all existing ingress rules from security group to compare against current O365 list
    """
    logger.info("Getting all existing ingress rules from Security Group to compare...")
    try:
        data = ec2.describe_security_groups(
            GroupIds=[sg]
        )
    except ClientError as e:
        print(e)
    existing_ip_ranges = list(data['SecurityGroups'][0]['IpPermissions'][0]['IpRanges'])
    existing_ip_list = [i['CidrIp'] for i in existing_ip_ranges]
    return existing_ip_list.sort()


def update_ingress_rules(sg, existing_ip_list):
    remove_ingress_rule(sg=sg, ip_list=list(set(existing_ip_list) - set(o365_ips)))
    add_ingress_rules(sg=sg, ip_list=list(set(o365_ips) - set(existing_ip_list)))


def remove_ingress_rule(sg, ip_list):
    try:
        data = ec2.revoke_security_group_ingress(
            GroupId=sg,
            IpPermissions=ip_list)
        print('MF Ingress Successfully REVOKED for {}'.format(sg))
    except ClientError as e:
        print(e)


def add_ingress_rules(sg, ip_list):
    """
    Set ingress rules on both MF-IS and MF-OS ELB SGs to allow all O365 published IPs to connect.
    """
    logger.info("Setting ingress rules for MF-IS and MF-OS ELB Security Groups.")
    for ip in ip_list:
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
            print('Ingress Rule Successfully Set for {}'.format(sg))
        except ClientError as e:
            print(e)


def mf_elb_o365_ip_sync_handler(event, context):
    logger.info("got event {0}".format(event))
    logger.info("Received event: {0}".format(json.dumps(event)))
    logger.info("Log stream name: {0}".format(context.log_stream_name))
    logger.info("Log group name: {0}".format(context.log_group_name))
    logger.info("Request ID: {0}".format(context.aws_request_id))
    logger.info("Mem. limits(MB): {0}".format(context.memory_limit_in_mb))

    o365_api_call()

    for sg in mf_security_groups:
        existing_ip_list = retrieve_existing_ingress_rules(sg=sg)
        if o365_ips == existing_ip_list:
            logger.info("No changes detected between O365 IP ranges and Ingress Rules.")
        else:
            update_ingress_rules(sg=sg, existing_ip_list=existing_ip_list)

    logger.info("===FINISHED=== MF ELB O365 IP Sync.")
