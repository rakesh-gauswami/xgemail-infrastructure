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
    "eml100hnd": 'Z00959292MKFE2F8O3SVR',
    "eml100syd": 'Z1011819W5HGRZRGPENU',
    "eml100yul": 'Z1014554AERXECT6FME1',
    "eml100bom": 'Z0317622WPHQXEY8RA1S',
    "eml100gru": 'Z04474823GZ4M87DRPHJB'
}

# HostedZoneIDs for PTR records based on region
ptrzoneid = {
    "prod-us-east-2": 'Z082430616C3R7N712JOG',
    "prod-eu-west-1": 'Z0901709WN6V809KXTJ4',
    "prod-us-west-2": 'Z05672293M9YCC10NXQZ5',
    "prod-us-west-2-spare": 'Z00382154IYYFLZVB78D',
    "prod-us-east-2-spare": 'Z00800781RZ26AD1QM60Z',
    "prod-eu-central-1": 'Z0601549389CMBAMATPSJ',
    "eml100hnd-ap-northeast-1": 'Z0082350LSQ96QL4AU36',
    "eml100syd-ap-southeast-2": 'Z089354717CN71A5M9BXE',
    "eml100yul-ca-central-1": 'Z03549533C0Q1VKM8ZL9I',
    "eml100bom-ap-south-1": 'Z082182521MCSKZNM6SAW',
    "eml100gru-sa-east-1": 'Z08364685K2G9Z3E6EAT'
}


def update_byoip_a_record(ip, dnsrecord):
    response = ""
    ip = "{{\"Value\": \"{}\"}}".format(ip)
    new_value = json.loads(ip)
    try:
        existing_records = route53_client.list_resource_record_sets(
            HostedZoneId=azoneid.get(account, "A HostedZoneId not found for account provided."),
            StartRecordName=dnsrecord,
            StartRecordType='A',
            MaxItems='1'
        )
        if dnsrecord == existing_records["ResourceRecordSets"][0]["Name"][:-1]:
            existing_values = existing_records["ResourceRecordSets"][0]["ResourceRecords"]
            print("Found existing A records: " + str(existing_values))
            if new_value not in existing_values:
                print("Adding new value to existing A records.")
                existing_values.append(new_value)
            else:
                print("Records already current.")
            values = existing_values
        else:
            values = json.loads("[" + ip + "]")
        print("Creating A records: " + dnsrecord + " for IPs: " + str(values))
        response = route53_client.change_resource_record_sets(
            HostedZoneId=azoneid.get(account, "A HostedZoneId not found for account provided."),
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': dnsrecord,
                            'Type': 'A',
                            'TTL': ttl,
                            'ResourceRecords': values
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
parser.add_argument('account', choices=['inf', 'dev', 'qa', 'prod', 'eml100hnd', 'eml100syd', 'eml100yul', 'eml100bom', 'eml100gru'],
                    help='Account/Environment to run automation.')
parser.add_argument('region', choices=['eu-west-1', 'eu-central-1', 'us-west-2', 'us-east-2', 'ap-northeast-1', 'ap-southeast-2', 'ca-central-1', 'ap-south-1', 'sa-east-1', 'us-west-2-spare', 'us-east-2-spare'],
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
    if not byoip['DnsRecord'] or not byoip['EipName']:
        continue
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
