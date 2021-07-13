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
import time
import os
import socket
from datetime import datetime, timedelta
from botocore.exceptions import ClientError, WaiterError
from botocore.waiter import WaiterModel
from botocore.waiter import create_waiter_with_client


print('Loading function')

logger = logging.getLogger()

if os.environ.get('LOG_LEVEL') is None:
    logger.setLevel('INFO')
else:
    logger.setLevel(logging.getLevelName(os.environ.get('LOG_LEVEL').strip()))


class MultiEip:
    def __init__(self, instance_id):
        account = os.environ['ACCOUNT']
        region = os.environ['AWS_REGION']
        self.session = boto3.session.Session(region_name=region)
        self.ec2 = self.session.resource('ec2')
        """:type: pyboto3.ec2 """
        self.ec2_client = self.ec2.meta.client
        """:type: pyboto3.ec2 """
        self.ssm = self.session.client('ssm')
        """:type: pyboto3.ssm """
        self.instance = self.ec2.Instance(instance_id)
        self.eni, self.attachment_id  = self.get_eni()
        self.eip_count = self.get_eip_count()
        self.assign_private_ips()
        self.private_ips = self.fetch_private_ips()
        self.public_ips = self.assign_multi_eips()
        self.associate_eip_private_ip()


    def get_eip_count(self):
        for tag in self.instance.tags:
            if 'eip_count' in tag['Key']:
                return tag['Value']
            else:
                return 1


    def get_eni(self):
        return (self.instance.network_interfaces_attribute[0]['NetworkInterfaceId'],self.instance.network_interfaces_attribute[0]['Attachment']['AttachmentId'])


    def assign_private_ips(self):
        result = self.ec2_client.assign_private_ip_addresses(NetworkInterfaceId=self.eni, SecondaryPrivateIpAddressCount=self.eip_count)
        return result['AssignedPrivateIpAddresses']


    def assign_multi_eips(self):
        for private_ip in self.private_ips:
            eip = self.get_clean_eip()
            if eip is not None:
                if self.associate_address(allocation_id=eip['AllocationId'], instance_id=self.instance.id, private_ip=private_ip):
                    logger.info("Associating EIP {} to Private IP {} on Instance: {}.".format(eip['PublicIp'], private_ip, self.instance.id))
                    return True
                else:
                    logger.error("Unable to associate EIP {} to Private IP {} on Instance: {}.".format(eip['PublicIp'], private_ip, self.instance.id))
                    return False
            else:
                logger.error("Unable to obtain EIP for Instance: {}.".format(self.instance.id))
        return False


    def fetch_private_ips(self):
        nic = self.ec2_client.describe_network_interfaces(NetworkInterfaceIds=[self.eni])
        return [private_ip['PrivateIpAddress'] for private_ip in nic['NetworkInterfaces'][0]['PrivateIpAddresses']]


    def add_tags_dict(self, addresses):
        """
        Add a derived 'TagsDict' entry to each address in the given list.
        """
        for address in addresses:
            tags = dict()
            for tag_entry in address["Tags"]:
                tags[tag_entry["Key"]] = tag_entry["Value"]
            address["TagsDict"] = tags


    def lookup_eip(self, eip):
        """
        Lookup EIP to check if it is in fact an EIP and return the Allocation Id and Association Id.
        """
        logger.info("Looking up EIP: {}.".format(eip))
        try:
            eip = self.ec2_client.describe_addresses(
                PublicIps=[eip]
            )['Addresses'][0]
        except ClientError as e:
            if e.response['Error']['Code'] == 'InvalidAddress.NotFound':
                logger.exception("The current Public IP Address is not an Elastic IP Address.")
            return None
        else:
            return eip


    def get_clean_eip(self):
        """
        Find an xgemail-outbound EIP that is NOT listed on any blacklists and is NOT attached to an instance.
        """
        instance_type = [ t['Value'] for t in self.instance.tags if t['Key'] == 'Application' ][0]
        logger.info("Locating a clean {} EIP to use.".format(instance_type))
        try:
            addresses = self.ec2_client.describe_addresses(
                Filters=[
                    {
                        'Name': 'tag:Name', 'Values': [instance_type]
                    }
                ]
            )['Addresses']
        except ClientError as e:
            logger.exception("Unable to describe addresses. {}".format(e))
            return None

        if addresses is not None:
            self.add_tags_dict(addresses)
            addresses.sort(key=lambda address: (
                int(address['TagsDict']['blacklist']),
                address['TagsDict']['snds_score'],
                address['TagsDict']['talos_score'],
                -float(address['TagsDict']['last_month_volume']),
                -float(address['TagsDict']['last_day_volume']),
                address['TagsDict']['detached']
                )
            )
            for address in addresses:
                if 'AssociationId' not in address:
                    return address
        else:
            return None


    def associate_address(self, allocation_id, instance_id, private_ip):
        """
        Associate an EIP to an EC2 Instance.
        """
        logger.info("Associating Private IP {} with EIP Allocation Id:{} on Instance: {}".format(private_ip, allocation_id, instance_id))
        try:
            self.ec2_client.associate_address(
                AllocationId=allocation_id,
                AllowReassociation=False,
                InstanceId=instance_id,
                PrivateIpAddress=private_ip
            )
        except Exception as e:
            logger.error("Unable to associate elastic IP {}".format(e))
            return False
        else:
            return True


def complete_lifecycle_action(autoscaling_group_name, lifecycle_hook_name, lifecycle_action_token, lifecycle_action_result):
    """
    Completes the lifecycle action for the specified token or instance with the specified result.
    """
    asg = boto3.client('autoscaling')
    """:type: pyboto3.autoscaling """
    try:
        asg.complete_lifecycle_action(
            LifecycleHookName=lifecycle_hook_name,
            AutoScalingGroupName=autoscaling_group_name,
            LifecycleActionToken=lifecycle_action_token,
            LifecycleActionResult=lifecycle_action_result,
        )
    except ClientError as e:
        logger.exception("Exception completing lifecycle hook {}".format(e.response['Error']['Code']))
        return False
    else:
        return True


def multi_eip_rotation_handler(event, context):
    logger.info('got event{}'.format(event))
    print("Received event: " + json.dumps(event))
    print("Log stream name:", context.log_stream_name)
    print("Log group name:", context.log_group_name)
    print("Request ID:", context.aws_request_id)
    print("Mem. limits(MB):", context.memory_limit_in_mb)

    if 'EC2InstanceId' in event:
        logger.info("Lambda Function triggered from SSM Automation Document.")
        instance_id = event['EC2InstanceId']
        #if event.get('Eip'):
        #    eip = event['Eip']
        #else:
        #    eip = None
        #return rotate_multi_eips(ec2_instance, eip)
        pass

    elif 'EC2InstanceId' in event['detail']:
        logger.info("Lambda Function triggered from Instance Launching Lifecycle Hook.")
        instance_id = event['detail']['EC2InstanceId']
        autoscaling_group_name = event['detail']['AutoScalingGroupName']
        lifecycle_hook_name = event['detail']['LifecycleHookName']
        lifecycle_action_token = event['detail']['LifecycleActionToken']

        if MultiEip(instance_id):
            logger.info("Completing lifecycle action with CONTINUE")
            lifecycle_action_result='CONTINUE'
        else:
            logger.error("Completing lifecycle action with ABANDON")
            lifecycle_action_result='ABANDON'

        return complete_lifecycle_action(
            autoscaling_group_name,
            lifecycle_hook_name,
            lifecycle_action_token,
            lifecycle_action_result
        )
    else:
        return False
