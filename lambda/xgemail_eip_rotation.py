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

account = os.environ['ACCOUNT']
region = os.environ['AWS_REGION']
ssm_postfix_service = os.environ['SSM_POSTFIX_SERVICE']
ssm_update_hostname = os.environ['SSM_UPDATE_HOSTNAME']

logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger()

if os.environ.get('LOG_LEVEL') is None:
    logger.setLevel('INFO')
else:
    logger.setLevel(logging.getLevelName(os.environ.get('LOG_LEVEL').strip()))

session = boto3.session.Session(region_name=region)
ec2 = session.resource('ec2')
""":type: pyboto3.ec2 """
ec2_client = ec2.meta.client
""":type: pyboto3.ec2 """
ssm = session.client('ssm')
""":type: pyboto3.ssm """


def eip_rotation_handler(event, context):
    logger.info('got event{}'.format(event))
    print("Received event: " + json.dumps(event))
    print("Log stream name:", context.log_stream_name)
    print("Log group name:", context.log_group_name)
    print("Request ID:", context.aws_request_id)
    print("Mem. limits(MB):", context.memory_limit_in_mb)

    if 'EC2InstanceId' in event:
        logger.info("Lambda Function triggered from SSM Automation Document.")
        ec2_instance = ec2.Instance(event['EC2InstanceId'])
        if event.get('Eip'):
            eip = event['Eip']
        else:
            eip = None
        return rotate_single_eip(ec2_instance, eip)

    elif 'EC2InstanceId' in event['detail']:
        logger.info("Lambda Function triggered from Instance Launching Lifecycle Hook.")
        ec2_instance = ec2.Instance(event['detail']['EC2InstanceId'])
        autoscaling_group_name = event['detail']['AutoScalingGroupName']
        lifecycle_hook_name = event['detail']['LifecycleHookName']
        lifecycle_action_token = event['detail']['LifecycleActionToken']

        if initial_eip(instance=ec2_instance):
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
        logger.info("Lambda Function triggered from CloudWatch Scheduled Event for EIP Rotation.")
        return rotate_all_eips()


def initial_eip(instance):
    """
    If triggered via Lifecycle Hook then just assign an EIP.
    """
    new_eip = get_clean_eip(instance)
    if new_eip is not None:
        if associate_address(allocation_id=new_eip['AllocationId'], instance_id=instance.id):
            logger.info("===FINISHED=== Attaching initial EIP on Instance: {}.".format(instance.id))
            return True
        else:
            logger.error("Unable to attach EIP to Instance: {}.".format(instance.id))
            return False
    else:
        logger.error("Unable to obtain EIP for Instance: {}.".format(instance.id))
        return False


def rotate_eip(instance, current_eip, new_eip):
    hostname = socket.gethostbyaddr(new_eip['PublicIp'])[0]
    if postfix_service(instance_id=instance.id, cmd='stop'):
        if disassociate_address(eip=current_eip):
            if associate_address(allocation_id=new_eip['AllocationId'], instance_id=instance.id):
                if update_hostname(instance_id=instance.id, hostname=hostname):
                    logger.info("Successfully rotated EIP on Instance: {}.".format(instance.id))
                    return True
                else:
                    logger.error("Unable to Update Hostname on Instance: {}.".format(instance.id))
                    return False
            else:
                logger.error("There was a problem with EIP association for Instance: {}.".format(instance.id))
                return False
        else:
            postfix_service(instance_id=instance.id, cmd='start')
            logger.error("There was a problem with EIP disassociation for Instance: {}.".format(instance.id))
            return False
    else:
        logger.error("Unable to stop Postfix Service on Instance: {}.".format(instance.id))
        return False


def rotate_all_eips():
    """
    If triggered from scheduled event rotate all EIP's.
    """
    rotation_complete = True

    for instance in get_instances_by_name():
        if (datetime.now(instance.launch_time.tzinfo) - instance.launch_time).total_seconds() <= 1800:
            logger.info("Instance Id: {} was recently deployed. Skipping".format(instance.id))
            continue
        current_eip = lookup_eip(eip=instance.public_ip_address)
        if current_eip is None:
            continue
        new_eip = get_clean_eip(instance)

        rotation_complete &= rotate_eip(instance, current_eip, new_eip)

    logger.info("===FINISHED=== Rotating Outbound Delivery EIP's.")
    return rotation_complete


def rotate_single_eip(instance, eip):
    """
    If triggered from SSM rotate a single EC2 Instance's EIP.
    """
    current_eip = lookup_eip(eip=instance.public_ip_address)
    if eip == None:
        new_eip = get_clean_eip(instance)
    else:
        new_eip = lookup_eip(eip=eip)

    return rotate_eip(instance, current_eip, new_eip)


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
                    'CloudEmail:mf-inbound-delivery:*',
                    'CloudEmail:mf-outbound-delivery:*',
                    'CloudEmail:mf-inbound-xdelivery:*',
                    'CloudEmail:mf-outbound-xdelivery:*',
                    'CloudEmail:risky-delivery:*',
                    'CloudEmail:risky-xdelivery:*',
                    'CloudEmail:beta-delivery:*',
                    'CloudEmail:beta-xdelivery:*',
                    'CloudEmail:delta-delivery:*',
                    'CloudEmail:delta-xdelivery:*'
                ]
            }
        ]
    )
    return instances


def command_invocation_waiter(command_id, instance_id):
    """
    SSM Command Invocation Waiter.
    """
    delay = 5
    max_attempts = 20
    waiter_name = 'CommandComplete'

    waiter_config = {
          "version": 2,
          "waiters": {
              waiter_name: {
                  "operation": "GetCommandInvocation",
                  "maxAttempts": max_attempts,
                  "delay": delay,
                  "acceptors": [
                      {
                          "state": "retry",
                          "matcher": "path",
                          "argument": "Status",
                          "expected": "Pending"
                      },
                      {
                          "state": "retry",
                          "matcher": "path",
                          "argument": "Status",
                          "expected": "InProgress"
                      },
                      {
                          "state": "retry",
                          "matcher": "path",
                          "argument": "Status",
                          "expected": "Delayed"
                      },
                      {
                          "state": "success",
                          "matcher": "path",
                          "argument": "Status",
                          "expected": "Success"
                      },
                      {
                          "state": "failure",
                          "matcher": "path",
                          "argument": "Status",
                          "expected": "Cancelled"
                      },
                      {
                          "state": "failure",
                          "matcher": "path",
                          "argument": "Status",
                          "expected": "TimedOut"
                      },
                      {
                          "state": "failure",
                          "matcher": "path",
                          "argument": "Status",
                          "expected": "Failed"
                      },
                      {
                          "state": "retry",
                          "matcher": "path",
                          "argument": "Status",
                          "expected": "Cancelling"
                      },
                      {
                          "state": "retry",
                          "matcher": "error",
                          "expected": "InvocationDoesNotExist"
                      }
                  ]
              }
          }
    }

    waiter_model = WaiterModel(waiter_config)
    custom_waiter = create_waiter_with_client(waiter_name, waiter_model, ssm)

    try:
        custom_waiter.wait(CommandId=command_id, InstanceId=instance_id)

    except WaiterError as we:
        if "Max Attempts Exceeded" in we.message:
            logger.exception("Timeout")
        else:
            logger.exception(we.message)
        return False
    else:
        return True


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
        return command_invocation_waiter(command_id=ssmresponse['Command']['CommandId'], instance_id=instance_id)


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
        return command_invocation_waiter(command_id=ssmresponse['Command']['CommandId'], instance_id=instance_id)


def add_tags_dict(addresses):
    """
    Add a derived 'TagsDict' entry to each address in the given list.
    """
    for address in addresses:
        tags = dict()
        for tag_entry in address["Tags"]:
            tags[tag_entry["Key"]] = tag_entry["Value"]
        address["TagsDict"] = tags


def lookup_eip(eip):
    """
    Lookup EIP to check if it is in fact an EIP and return the Allocation Id and Association Id.
    """
    logger.info("Looking up EIP: {}.".format(eip))
    try:
        eip = ec2_client.describe_addresses(
            PublicIps=[eip]
        )['Addresses'][0]
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidAddress.NotFound':
            logger.exception("The current Public IP Address is not an Elastic IP Address.")
        return None
    else:
        return eip


def get_clean_eip(instance):
    """
    Find an xgemail-outbound EIP that is NOT listed on any blacklists and is NOT attached to an instance.
    """
    instance_type = [ t['Value'] for t in instance.tags if t['Key'] == 'Application' ][0]
    logger.info("Locating a clean {} EIP to use.".format(instance_type))
    try:
        addresses = ec2_client.describe_addresses(
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
        add_tags_dict(addresses)
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


def associate_address(allocation_id, instance_id):
    """
    Associate an EIP to an EC2 Instance.
    """
    logger.info("Associating EIP Allocation Id:{} with Instance: {}".format(allocation_id, instance_id))
    try:
        ec2_client.associate_address(
            AllocationId=allocation_id,
            AllowReassociation=False,
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


def complete_lifecycle_action(autoscaling_group_name, lifecycle_hook_name, lifecycle_action_token, lifecycle_action_result):
    """
    Completes the lifecycle action for the specified token or instance with the specified result.
    """
    asg = session.client('autoscaling')
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
