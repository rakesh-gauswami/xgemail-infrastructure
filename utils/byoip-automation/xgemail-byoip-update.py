#!/usr/bin/env python

import boto3
from botocore.exceptions import ClientError
import json
import sys
import ipaddress

# HostedZoneIDs for A records:
inf = 'ZN9712Y506MUM'
dev = 'ZBKEJ4BMWTGLP'
qa = 'Z3PNQYIZM8851A'
prod = 'Z1LGZDUSPJAUO4'

regions = ["us-east-2", "us-west-2", "eu-central-1", "eu-west-1"]
region = 'test'
ttl = 60
res = ""
azoneid = inf
test = True

# HostedZoneIDs for PTR records:
ptrzoneid={
    "us-east-2": 'Z082430616C3R7N712JOG',
    "us-west-2": 'Z05672293M9YCC10NXQZ5',
    "eu-central-1": 'Z0601549389CMBAMATPSJ',
    "eu-west-1": 'Z0901709WN6V809KXTJ4',
    "test": 'Z078753720OPOKCR4XUET'
}

# HostedZoneIDs for FSC PTR records:
# ap-s2-fsc-hostedzoneid = 'Z04757282YOTSCLF8L9GW'
# ap-n1-fsc-hostedzoneid = 'Z07508741CVLNIIET1065'
# ca-c1-fsc-hostedzoneid = 'Z00800781RZ26AD1QM60Z'
# us-west-2-fsc-hostedzoneid = 'Z00382154IYYFLZVB78D'


def update_byoip_a_record(ip, dnsrecord):
    response = ""
    try:
        print("Creating A record: " + dnsrecord + " for IP: " + ip)
        response = route53_client.change_resource_record_sets(
            HostedZoneId=azoneid,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
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
            HostedZoneId=ptrzoneid.get(region, "Invalid region."),
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


if test:
    session = boto3.Session(profile_name='inf', region_name='eu-west-1')
    route53_client = session.client('route53')
    eip_client = session.client('ec2')

    with open('test.json', 'r') as f:
        records_dict = json.load(f)

    for byoip in records_dict:
        print(byoip['IpAddress'])
        res = update_byoip_a_record(ip=byoip['IpAddress'], dnsrecord=byoip['DnsRecord'])
        print("Finished attempting DNS A record creation")
        print(res)
        res = update_byoip_ptr_record(ip=byoip['IpAddress'], dnsrecord=byoip['DnsRecord'])
        print("Finished attempting DNS PTR record creation")
        print(res)
        res = update_byoip_tag(ip=byoip['IpAddress'], eipname=byoip['EipName'])
        print("Finished attempting EIP tagging")
        print(res)

    sys.exit("Test run performed in INF account.")

for region in regions:
    session = boto3.Session(profile_name='inf', region_name=region)
    route53_client = session.client('route53')
    eip_client = session.client('ec2')

    with open('xgemail-byoip-address-config-{0}.json'.format(region), 'r') as f:
        records_dict = json.load(f)

    for byoip in records_dict:
        print(byoip['IpAddress'])
        res = update_byoip_a_record(ip=byoip['IpAddress'], dnsrecord=byoip['DnsRecord'])
        print("Finished attempting DNS A record creation")
        print(res)
        res = update_byoip_ptr_record(ip=byoip['IpAddress'], dnsrecord=byoip['DnsRecord'])
        print("Finished attempting DNS PTR record creation")
        print(res)
        res = update_byoip_tag(ip=byoip['IpAddress'], eipname=byoip['EipName'])
        print("Finished attempting EIP tagging")
        print(res)
        sys.exit("BYOIP automation completed.")
