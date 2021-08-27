#!/usr/bin/env python

import boto3
from botocore.exceptions import ClientError
import json
import sys
import ipaddress
import argparse

# TTL value to apply to all A and PTR Route53 records
ttl = 60

# HostedZoneIDs for A records based on account name
azoneid = {
    "inf": 'ZN9712Y506MUM',
    "dev": 'ZBKEJ4BMWTGLP',
    "qa": 'Z3PNQYIZM8851A',
    "prod": 'Z1LGZDUSPJAUO4',
    "ap-s2-fsc": 'Z04757282YOTSCLF8L9GW',
    "ap-n1-fsc": 'Z07508741CVLNIIET1065',
    "ca-c1-fsc": 'Z00800781RZ26AD1QM60Z',
    "us-west-2-fsc": 'Z00382154IYYFLZVB78D'
}

# HostedZoneIDs for PTR records based on region
ptrzoneid = {
    "prod-us-east-2": 'Z082430616C3R7N712JOG',
    "prod-us-west-2": 'Z05672293M9YCC10NXQZ5',
    "prod-eu-central-1": 'Z0601549389CMBAMATPSJ',
    "prod-eu-west-1": 'Z0901709WN6V809KXTJ4'
}


def update_byoip_a_record(ip, dnsrecord):
    response = ""
    try:
        print("Creating A record: " + dnsrecord + " for IP: " + ip)
        response = route53_client.change_resource_record_sets(
            HostedZoneId=azoneid.get(account, "A HostedZoneId not found for account provided."),
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'CREATE',
                        'ResourceRecordSet': {
                            'Name': dnsrecord,
                            'Type': 'A',
                            'TTL': ttl,
                            'ResourceRecords': [
                                {
                                    'Value': ip
                                }
                            ]
                        }
                    }
                ]
            }
        )
    except ClientError as e:
        print("Failed to set DNS")
        print(e.response)
    return response


def update_byoip_ptr_record(ip, dnsrecord):
    response = ""
    try:
        print("Creating PTR record: " + dnsrecord + " for IP: " + ip)
        response = route53_client.change_resource_record_sets(
            HostedZoneId=ptrzoneid.get(account+'-'+region, "PTR HostedZoneId not found for region provided."),
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': ipaddress.ip_address(ip).reverse_pointer,
                            'Type': 'PTR',
                            'TTL': ttl,
                            'ResourceRecords': [
                                {
                                    'Value': dnsrecord
                                }
                            ]
                        }
                    }
                ]
            }
        )
    except ClientError as e:
        print("Failed to set DNS")
        print(e.response)
    return response


def update_byoip_tag(ip, eipname):
    response = ""
    try:
        eipalloc = eip_client.describe_addresses(Filters=[
            {
                'Name': 'public-ip',
                'Values': [
                    ip
                ]
            }
        ]
        )
        response = eip_client.create_tags(
            Resources=[
                eipalloc['Addresses'][0]['AllocationId']
            ],
            Tags=[
                {
                    'Key': 'Name',
                    'Value': eipname
                },
            ]
        )
    except ClientError as e:
        print("Failed to set EIP tag")
        print(e.response)
    return response


parser = argparse.ArgumentParser(description='BYOIP automation of Route53 records and EIP tags.')
parser.add_argument('account', choices=['inf', 'dev', 'qa', 'prod'],
                    help='Account/Environment to run automation.')
parser.add_argument('region', choices=['eu-west-1', 'eu-central-1', 'us-west-2', 'us-east-2'],
                    help='Region to run automation.')
args = parser.parse_args()
account = args.account
region = args.region
session = boto3.Session(profile_name=account, region_name=region)
route53_client = session.client('route53')
eip_client = session.client('ec2')

try:
    with open('xgemail-byoip-address-config-{0}-{1}.json'.format(account, region), 'r') as f:
        records_dict = json.load(f)

except IOError:
    print("Could not read json file:", f)

for byoip in records_dict:
    print(byoip['IpAddress'])

    print("Attempting DNS A record creation")
    res = update_byoip_a_record(ip=byoip['IpAddress'], dnsrecord=byoip['DnsRecord'])
    print(res)
    print("Finished attempting DNS A record creation")

    print("Attempting DNS PTR record creation")
    res = update_byoip_ptr_record(ip=byoip['IpAddress'], dnsrecord=byoip['DnsRecord'])
    print(res)
    print("Finished attempting DNS PTR record creation")

    print("Attempting EIP tagging")
    res = update_byoip_tag(ip=byoip['IpAddress'], eipname=byoip['EipName'])
    print(res)
    print("Finished attempting EIP tagging")

sys.exit("BYOIP automation complete.")
