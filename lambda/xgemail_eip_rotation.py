"""
Description here.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

from __future__ import print_function

import boto3
import logging
import json
import time
import os
from datetime import datetime, timedelta
from botocore.exceptions import ClientError


print('Loading function')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region = os.environ['AWS_REGION']
account = os.environ['ACCOUNT']
ssm_postfix_service = os.environ['SSM_POSTFIX_SERVICE']
ssm_update_hostname = os.environ['SSM_UPDATE_HOSTNAME']

session = boto3.session.Session(region_name=region)
ec2 = session.resource('ec2')
""":type: pyboto3.ec2 """
ec2_client = ec2.meta.client
""":type: pyboto3.ec2 """
ssm = boto3.client('ssm')
""":type: pyboto3.ssm """


def eip_rotation_handler(event, context):
    logger.info('got event{}'.format(event))
    print("Received event: " + json.dumps(event))
    print("Log stream name:", context.log_stream_name)
    print("Log group name:", context.log_group_name)
    print("Request ID:", context.aws_request_id)
    print("Mem. limits(MB):", context.memory_limit_in_mb)

    for instance in get_instances_by_name():
        if (datetime.now(instance.launch_time.tzinfo) - instance.launch_time).total_seconds() <= 1800:
            logger.info("Instance Id: {} was recently deployed. Skipping".format(instance.id))
            continue
        current_eip = get_current_eip(current_eip=instance.public_ip_address)
        if current_eip is None:
            continue
        new_eip = get_clean_eip()
        hostname = 'delivery-' + new_eip['PublicIp'].replace('.', '-') + '-' + region + '.' + account + '.hydra.sophos.com'
        if postfix_service(instance_id=instance.id, cmd='stop'):
            if disassociate_address(eip=current_eip):
                if associate_address(allocation_id=new_eip['AllocationId'], instance_id=instance.id):
                    if update_hostname(instance_id=instance.id, hostname=hostname):
                        logger.info("Successfully rotated EIP on Instance: {}.".format(instance.id))
            else:
                postfix_service(instance_id=instance.id, cmd='start')
                logger.info("There was a problem with EIP rotation for Instance: {}.".format(instance.id))
                continue
        else:
            logger.info("Unable to stop Postfix Service on Instance:: {}.".format(instance.id))
            continue
    logger.info("===FINISHED=== Rotating Outbound Delivery EIP's.")


def get_instances_by_name():
    """
    Get EC2 Instances matching filter.
    """
    instances = ec2.instances.filter(
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': ['running']
            },
            {
                'Name': 'tag:Name',
                'Values': [
                    'CloudEmail:internet-delivery:*',
                    'CloudEmail:internet-xdelivery:*'
                ]
            }
        ]
    )
    return instances


def postfix_service(instance_id, cmd):
    """
    Run SSM Command to Start or Stop the Postfix Service.
    """
    logger.info("Executing {} Postfix SSM Document, for Instance Id: {}".format(cmd, instance_id))
    try:
        ssmresponse = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName=ssm_postfix_service,
            Parameters={'cmd': [cmd]}
        )
    except ClientError as e:
        logger.exception("Unable to send SSM command. {}".format(e))
        return False
    else:
        ssm_status = ssmresponse['Command']['Status']
        if ssm_status == 'Success':
            return True
        while ssm_status == 'Pending' or ssm_status == 'InProgress':
            time.sleep(3)
            ssm_status = ssm.list_commands(
                CommandId=ssmresponse['Command']['CommandId']
            )['Commands'][0]['Status']
        if ssm_status != 'Success':
            return False
        return True


def update_hostname(instance_id, hostname):
    """
    Run SSM Command to update the hostname and start the postfix service.
    """
    logger.info("Executing Update Hostname SSM Document, for Instance Id: {} with hostname: {}".format(instance_id, hostname))
    try:
        ssmresponse = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName=ssm_update_hostname,
            Parameters={'hostname': [hostname]}
        )
    except ClientError as e:
        logger.exception("Unable to send SSM command. {}".format(e))
        return False
    else:
        ssm_status = ssmresponse['Command']['Status']
        if ssm_status == 'Success':
            return True
        while ssm_status == 'Pending' or ssm_status == 'InProgress':
            time.sleep(3)
            ssm_status = ssm.list_commands(
                CommandId=ssmresponse['Command']['CommandId']
            )['Commands'][0]['Status']
        if ssm_status != 'Success':
            return False
        return True


def add_tags_dict(addresses):
    """
    Add a derived 'TagsDict' entry to each address in the given list.
    """
    for address in addresses:
        tags = dict()
        for tag_entry in address["Tags"]:
            tags[tag_entry["Key"]] = tag_entry["Value"]
        address["TagsDict"] = tags


def get_current_eip(current_eip):
    """
    Lookup current EIP to check if it is in fact an EIP and return the Allocation Id and Association Id.
    """
    logger.info("Looking up current EIP.")
    try:
        eip = ec2_client.describe_addresses(
            PublicIps=[current_eip]
        )['Addresses'][0]
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidAddress.NotFound':
            logger.exception("The current Public IP Address is not an Elastic IP Address.")
        return None
    else:
        return eip


def get_clean_eip():
    """
    Find an xgemail-outbound EIP that is NOT listed on any blacklists and is NOT attached to an instance.
    """
    logger.info("Locating a clean EIP to use.")
    try:
        addresses = ec2_client.describe_addresses(
            Filters=[
                {
                    'Name': 'tag:Name', 'Values': ['xgemail-outbound']
                },
                {
                    'Name': 'tag:blacklist', 'Values': ['0']
                }
            ]
        )['Addresses']
    except ClientError as e:
        logger.exception("Unable to describe addresses. {}".format(e))

    add_tags_dict(addresses)
    addresses.sort(key=lambda address: address['TagsDict']['detached'])
    for address in addresses:
        if 'AssociationId' not in address:
            return address


def associate_address(allocation_id, instance_id):
    """
    Associate an EIP to an EC2 Instance.
    """
    logger.info("Associating EIP Allocation Id:{} with Instance: {}".format(allocation_id, instance_id))
    try:
        ec2_client.associate_address(
            AllocationId=allocation_id,
            InstanceId=instance_id
        )
    except Exception as e:
        logger.error("Unable to associate elastic IP {}".format(e))
        return False
    else:
        return True


def disassociate_address(eip):
    """
    Get EIP Info from describe_address. Disassociate the EIP from the EC2 Instance then tag the EIP with the time it was detached.
    """
    logger.info("Disassociating and Tagging EIP {}".format(eip['PublicIp']))
    try:
        ec2_client.disassociate_address(
            AssociationId=eip['AssociationId']
        )
        ec2_client.create_tags(
            Resources=[eip['AllocationId']],
            Tags=[
                {
                    'Key': 'detached',
                    'Value': datetime.now().strftime('%Y%m%d%H%M%S')
                }
            ]
        )
    except Exception as e:
        logger.exception("Unable to disassociate elastic IP {}".format(e))
        return False
    else:
        return True