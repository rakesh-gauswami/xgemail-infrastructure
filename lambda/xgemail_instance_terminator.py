"""
AWS Lambda Function that is triggered from a CloudWatch Events
regarding AutoScaling Lifecycle Hooks when an EC2 Instance
termination is initiated.

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
from botocore.exceptions import ClientError


print('Loading function')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region = os.environ['AWS_REGION']
ssm_document_name = os.environ['SSM_DOCUMENT_NAME']

session = boto3.session.Session(region_name=region)
ssm = session.client('ssm')
""":type: pyboto3.ssm """


def instance_terminator(event, context):
    logger.info("got event {}".format(event))
    logger.info("Received event: {}".format(json.dumps(event)))
    logger.info("Log stream name: {}".format(context.log_stream_name))
    logger.info("Log group name: {}".format(context.log_group_name))
    logger.info("Request ID: {}".format(context.aws_request_id))
    logger.info("Mem. limits(MB): {}".format(context.memory_limit_in_mb))

    send_ssm_command(
        region=event['region'],
        time=event['time'],
        autocaling_group_name=event['detail']['AutoScalingGroupName'],
        instance_id=event['detail']['EC2InstanceId'],
        lifecycle_hook_name=event['detail']['LifecycleHookName'],
        lifecycle_action_token=event['detail']['LifecycleActionToken'],
    )

    logger.info("===FINISHED=== Sending SSM Command.")


def send_ssm_command(region, time, autocaling_group_name, instance_id, lifecycle_hook_name, lifecycle_action_token):
    """
    Run SSM Command to run the shutdown script .
    """
    logger.info("Executing Instance Terminator SSM Document, for Instance Id: {} ".format(instance_id))
    try:
        ssmresponse = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName=ssm_document_name,
            Parameters={
                'Region': [region],
                'Time': [time],
                'AutoScalingGroupName': [autocaling_group_name],
                'InstanceId': [instance_id],
                'LifecycleHookName': [lifecycle_hook_name],
                'LifecycleActionToken': [lifecycle_action_token]
            }
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


