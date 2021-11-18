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
import json
import requests
import os
from botocore.exceptions import ClientError


print('Loading EIP Monitor Function')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region = os.environ['AWS_REGION']
TOKEN = os.getenv('TOKEN').strip()

session = boto3.session.Session(region_name=region)
ec2 = session.resource('ec2')
""":type: pyboto3.ec2 """
ec2_client = ec2.meta.client
""":type: pyboto3.ec2 """
s3 = session.client('s3')
""":type: pyboto3.s3 """


class HetrixToolsApi(object):
    def __init__(self):
        self.api_key = TOKEN
        self.base_url = 'https://api.hetrixtools.com/v2/' + self.api_key + '/'

    def blacklist_check(self, ip):
        """
        Blacklist checks an IPv4 IP address.
        """
        api = self.base_url + 'blacklist-check/ipv4/' + ip + '/'
        logger.info("Blacklist Check for IP: {}".format(ip))

        return self.hetrix_api_call(url=api)

    def blacklist_report(self, ip):
        """
        Get blacklist monitor info, including blacklisted RBLs.
        """
        api = self.base_url + 'blacklist/report/' + ip + '/'
        logger.info("Blacklist Report for IP: {}".format(ip))

        return self.hetrix_api_call(url=api)

    def list_blacklist_monitors(self):
        """
        Lists all of your Blacklist Monitors
        """
        logger.info("List Blacklist Monitors")
        blacklist_monitors = []
        api = self.base_url + 'blacklist/monitors/0/100/'
        monitors = self.hetrix_api_call(url=api)
        while True:
            for monitor in monitors[0]:
                if region in monitor['Label']:
                    blacklist_monitors.append(monitor)
            if 'Next' not in monitors[1]['Links']['Pages']:
                break
            monitors = self.hetrix_api_call(url=monitors[1]['Links']['Pages']['Next'])

        return blacklist_monitors

    def hetrix_api_call(self, url):
        """
        Performs the API call to HetrixTools API with the provided check.
        """
        request = requests.get(url=url)
        logger.info("HetrixTools API call result: {}".format(request.text))
        if request.status_code == 200:
            return request.json()

        return None


def get_associated_eips():
    """
    Find all xgemail EIPs that are associated (attached) to instances.
    """
    logger.info("Locating all xgemail EIPs that are associated with EC2 instances.")
    eips = []
    try:
        addresses = ec2_client.describe_addresses(
            Filters=[
                {
                    'Name': 'tag:Name', 'Values': ['xgemail-*']
                }
            ]
        )['Addresses']
    except ClientError as e:
        logger.exception("Unable to describe addresses. {}".format(e))

    for address in addresses:
        if 'AssociationId' in address:
            eips.append(address)

    return eips


def get_all_eips():
    """
    Find all xgemail EIPs.
    """
    logger.info("Locating all xgemail EIPs.")
    eips = []
    try:
        addresses = ec2_client.describe_addresses(
            Filters=[
                {
                    'Name': 'tag:Name', 'Values': ['xgemail-*']
                }
            ]
        )['Addresses']
    except ClientError as e:
        logger.exception("Unable to describe addresses. {}".format(e))

    for address in addresses:
        eips.append(address)

    return eips


def tag_eip(eip):
    """
    Get EIP Info from describe_address. Tag the EIP with the number of blacklists it is on.
    """
    logger.info("Tagging EIP {}".format(eip['PublicIp']))
    try:
        ec2_client.create_tags(
            Resources=[eip['AllocationId']],
            Tags=[
                {
                    'Key': 'blacklist',
                    'Value': eip['BlacklistedCount']
                }
            ]
        )
    except Exception as e:
        logger.exception("Unable to tag elastic IP {}".format(e))
        return False
    else:
        return True


def is_blacklist_updated(eip):
    """
    Compare HetrixTools blacklist_count to blacklist tag on EIP.
    Determine if tag_eip is necessary.
    """
    for tag in eip['Tags']:
        if 'blacklist' in tag['Key']:
            bl_value = tag['Value']
            if bl_value != eip['BlacklistedCount']:
                logger.warning("EIP: {} Blacklist value has changed. Blacklist tag will be updated.".format(eip['PublicIp']))
                return True
            else:
                logger.info("EIP: {} Blacklist value has not changed.".format(eip['PublicIp']))
                return False


def eip_monitor_handler(event, context):
    logger.info("got event {}".format(event))
    logger.info("Received event: {}".format(json.dumps(event)))
    logger.info("Log stream name: {}".format(context.log_stream_name))
    logger.info("Log group name: {}".format(context.log_group_name))
    logger.info("Request ID: {}".format(context.aws_request_id))
    logger.info("Mem. limits(MB): {}".format(context.memory_limit_in_mb))

    hetrix = HetrixToolsApi()
    blacklist_monitors = hetrix.list_blacklist_monitors()
    for eip in get_all_eips():
        for monitor in blacklist_monitors:
            if eip['PublicIp'] in monitor['Target']:
                eip['BlacklistedCount'] = str(monitor['Blacklisted_Count'])
                if is_blacklist_updated(eip):
                    tag_eip(eip=eip)
                    break

    logger.info("===FINISHED=== Xgemail Blacklist Checks.")
