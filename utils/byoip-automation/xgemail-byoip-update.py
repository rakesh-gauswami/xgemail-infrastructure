#!/usr/bin/env python

import boto3
from botocore.exceptions import ClientError
import json

env = ["inf", "dev", "qa", "prod"]
regions = ["us-east-2", "us-west-2", "eu-central-1", "eu-west-1"]
infhostedzoneid = 'ZN9712Y506MUM'
devhostedzoneid = 'ZBKEJ4BMWTGLP'
qahostedzoneid = 'Z3PNQYIZM8851A'
prodhostedzoneid = 'Z1LGZDUSPJAUO4'
hostedzoneid = infhostedzoneid
ttl = 60
res = ""


def update_byoip_dns(ipaddress, dnsrecord):
    response = ""
    try:
        print("Creating record: " + dnsrecord + " for IP: " + ipaddress)
        response = route53_client.change_resource_record_sets(
            HostedZoneId=hostedzoneid,
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
                                    'Value': ipaddress
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


def update_byoip_tag(ipaddress, eipname):
    response = ""
    try:
        eipalloc = eip_client.describe_addresses(Filters=[
            {
                'Name': 'public-ip',
                'Values': [
                    ipaddress
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


for region in regions:
    session = boto3.Session(profile_name='inf', region_name=region)
    route53_client = session.client('route53')
    eip_client = session.client('ec2')

    with open('xgemail-byoip-address-config-{0}.json'.format(region), 'r') as f:
        records_dict = json.load(f)

    for byoip in records_dict:
        print(byoip['IpAddress'])
        res = update_byoip_dns(ipaddress=byoip['IpAddress'], dnsrecord=byoip['DnsRecord'])
        print("Finished attempting DNS creation")
        print(res)
        res = update_byoip_tag(ipaddress=byoip['IpAddress'], eipname=byoip['EipName'])
        print("Finished attempting EIP tagging")
        print(res)
