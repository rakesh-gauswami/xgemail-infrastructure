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

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region = os.environ['AWS_REGION']
account = os.environ['ACCOUNT']
mf_security_groups = [os.environ['MFISSECURITYGROUP'], os.environ['MFOSSECURITYGROUP']]
ec2 = boto3.client('ec2')

logger.info("Starting MF ELB O365 IP Sync function")


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
    o365_ips=[]
    # Process for each record(id) of the endpoint JSON data
    for dict_o365_record in dict_o365_all:
        if 'ips' in dict_o365_record:
            list_ips = list(dict_o365_record['ips'])
            for ip in list_ips:
                if not re.match('^.+:', ip):
                    if ip not in o365_ips:
                        o365_ips.append(ip)
    o365_ips.sort()
    num_o365_ips = len(o365_ips)
    logger.info("Number of Office365 IPs to import : IPv4 host/net:" + str(num_o365_ips))
    return o365_ips


def retrieve_existing_ingress_rules(sg):
    """
    Retrieve all existing ingress rules from security group to compare against current O365 list
    """
    data=[]
    logger.info("Getting existing ingress rules from Security Group: " + sg)
    try:
        data = ec2.describe_security_groups(
            GroupIds=[sg]
        )
    except ClientError as e:
        print(e)
    try:
        existing_ip_ranges = list(data['SecurityGroups'][0]['IpPermissions'][0]['IpRanges'])
    except:
        logger.info("No existing ingress rules for ELB Security Group: " + sg)
        return
    else:
        existing_ip_list = [i['CidrIp'] for i in existing_ip_ranges]
        existing_ip_list.sort()
        return existing_ip_list


def update_ingress_rules(sg, o365_ips, existing_ip_list):
    if existing_ip_list:
        remove_ingress_rule(sg=sg, ip_list=list(set(existing_ip_list) - set(o365_ips)))
        add_ingress_rules(sg=sg, ip_list=list(set(o365_ips) - set(existing_ip_list)))
    else:
        add_ingress_rules(sg=sg, ip_list=o365_ips)


def remove_ingress_rule(sg, ip_list):
    logger.info("Attempting to revoke rules: " + str(ip_list))
    for ip in ip_list:
        for port in (25, 587):
            try:
                ec2.revoke_security_group_ingress(
                    GroupId=sg,
                    IpProtocol='tcp',
                    FromPort=port,
                    ToPort=port,
                    CidrIp=ip)
                logger.info("MF Ingress Successfully REVOKED " + str(ip) + ":" + str(port) + " for SG: " + sg)
            except ClientError as e:
                print(e)


def add_ingress_rules(sg, ip_list):
    """
    Set ingress rules on both MF-IS and MF-OS ELB SGs to allow all O365 published IPs to connect.
    """
    logger.info("Setting ingress rules for ELB Security Group: " + sg)
    for ip in ip_list:
        try:
            ec2.authorize_security_group_ingress(
                GroupId=sg,
                IpPermissions=[
                    {'IpProtocol': 'tcp',
                     'FromPort': 25,
                     'ToPort': 25,
                     'IpRanges': [{'CidrIp': ip, 'Description': 'Microsoft Office 365 Endpoint'}]},
                    {'IpProtocol': 'tcp',
                     'FromPort': 587,
                     'ToPort': 587,
                     'IpRanges': [{'CidrIp': ip, 'Description': 'Microsoft Office 365 Endpoint'}]}
                ])
            logger.info("Ingress Rule " + str(ip) + " Successfully Set for SG: " + sg)
        except ClientError as e:
            print(e)


def mf_elb_o365_ip_sync_lambda_handler(event, context):
    logger.info("got event {0}".format(event))
    logger.info("Received event: {0}".format(json.dumps(event)))
    logger.info("Log stream name: {0}".format(context.log_stream_name))
    logger.info("Log group name: {0}".format(context.log_group_name))
    logger.info("Request ID: {0}".format(context.aws_request_id))
    logger.info("Mem. limits(MB): {0}".format(context.memory_limit_in_mb))

    o365_ips = o365_api_call()
    for sg in mf_security_groups:
        existing_ip_list = retrieve_existing_ingress_rules(sg=sg)
        logger.info("O365 IPs: " + str(o365_ips))
        logger.info("SG IPs: " + str(existing_ip_list))
        if o365_ips == existing_ip_list:
            logger.info("No changes detected between O365 IPs and Ingress Rules for SG: " + sg)
        else:
            update_ingress_rules(sg=sg, o365_ips=o365_ips, existing_ip_list=existing_ip_list)

    logger.info("===FINISHED=== MF ELB O365 IP Sync.")
