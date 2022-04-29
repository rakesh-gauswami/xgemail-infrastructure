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
from datetime import datetime
from botocore.exceptions import ClientError, WaiterError


print('Loading function')

region = os.environ['AWS_REGION']
ssm_postfix_service = os.environ['SSM_POSTFIX_SERVICE']

logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger()

if os.environ.get('LOG_LEVEL') is None:
    logger.setLevel('INFO')
else:
    logger.setLevel(logging.getLevelName(os.environ.get('LOG_LEVEL').strip()))

session = boto3.session.Session(region_name=region)
ec2 = session.resource('ec2')
""":type: pyboto3.ec2 """


class MultiEip:
    def __init__(self, instance_id):
        self.session = boto3.session.Session(region_name=region)
        self.ec2 = self.session.resource('ec2')
        """:type: pyboto3.ec2 """
        self.ec2_client = self.ec2.meta.client
        """:type: pyboto3.ec2 """
        self.ssm = self.session.client('ssm')
        """:type: pyboto3.ssm """
        self.instance = self.ec2.Instance(instance_id)
        self.eni, self.attachment_id = self.get_eni()
        self.eip_count = self.get_eip_count()
        self.private_ips = []

    def get_eip_count(self):
        for tag in self.instance.tags:
            if 'EipCount' in tag['Key']:
                logger.debug("Found EipCount: {}.".format(tag['Value']))
                return int(tag['Value'])

        logger.warning("Could not find EipCount.")
        return int(1)

    def get_eni(self):
        return self.instance.network_interfaces_attribute[0]['NetworkInterfaceId'], self.instance.network_interfaces_attribute[0]['Attachment']['AttachmentId']

    def assign_private_ips(self):
        logger.info("Assigning {} Private IP(s) on Interface: {}.".format(self.eip_count, self.eni))
        try:
            result = self.ec2_client.assign_private_ip_addresses(NetworkInterfaceId=self.eni, SecondaryPrivateIpAddressCount=self.eip_count)
            logger.debug("Assigned Private IP Addresses: {}.".format(result['AssignedPrivateIpAddresses']))
            return True
        except ClientError as e:
            logger.exception("Unable to assign private ip addresses. {}".format(e))
            return False

    def associate_multi_eips(self):
        for private_ip in self.private_ips:
            while True:
                eip = self.get_clean_eip()
                if eip is not None:
                    logger.info("Associating EIP {} to Private IP {} on Instance: {}.".format(eip['PublicIp'], private_ip, self.instance.id))
                    if self.associate_address(eip=eip, instance_id=self.instance.id, private_ip=private_ip):
                        break
                else:
                    logger.error("Unable to obtain EIP for Instance: {}.".format(self.instance.id))
                    return False

        return True

    def fetch_private_ips(self):
        try:
            nic = self.ec2_client.describe_network_interfaces(NetworkInterfaceIds=[self.eni])
            logger.debug("Fetch private ips: {}".format([private_ip['PrivateIpAddress'] for private_ip in nic['NetworkInterfaces'][0]['PrivateIpAddresses']]))
            self.private_ips = [private_ip['PrivateIpAddress'] for private_ip in nic['NetworkInterfaces'][0]['PrivateIpAddresses']]
            return self.private_ips
        except ClientError as e:
            logger.exception("Unable to fetch private ip addresses. {}".format(e))
            return None

    def add_tags_dict(self, addresses):
        """
        Add a derived 'TagsDict' entry to each address in the given list.
        """
        for address in addresses:
            tags = dict()
            for tag_entry in address["Tags"]:
                tags[tag_entry["Key"]] = tag_entry["Value"]
            address["TagsDict"] = tags

    def get_clean_eip(self):
        """
        Find an xgemail-outbound EIP that is NOT listed on any blacklists and is NOT attached to an instance.
        """
        instance_type = [t['Value'] for t in self.instance.tags if t['Key'] == 'Application'][0]
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

    def get_current_eip(self, private_ip):
        """
        Get current EIP associated to private ip.
        """
        try:
            current_eip = self.ec2_client.describe_addresses(
                Filters=[
                    {
                        'Name': 'private-ip-address',
                        'Values': [private_ip]
                    }
                ]
            )['Addresses'][0]
        except ClientError as e:
            logger.exception("Unable to describe addresses {}".format(e))
        except IndexError as error:
            logger.exception("Unable to locate private IP {}".format(error))
        else:
            return current_eip

    def associate_address(self, eip, instance_id, private_ip):
        """
        Associate an EIP to an EC2 Instance.
        """
        logger.info("Associating Private IP {} with EIP Allocation Id:{} on Instance: {}".format(private_ip, eip['AllocationId'], instance_id))
        try:
            self.ec2_client.associate_address(
                AllocationId=eip['AllocationId'],
                AllowReassociation=False,
                InstanceId=instance_id,
                PrivateIpAddress=private_ip
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'Resource.AlreadyAssociated':
                logger.exception("EIP already associated {}".format(e))
            else:
                logger.exception("Unable to associate elastic IP {}".format(e))
        else:
            return True

    def disassociate_address(self, current_eip):
        """
        Get EIP Info from describe_address. Disassociate the EIP from the EC2 Instance then tag the EIP with the time it was detached.
        """
        logger.info("Disassociating and Tagging EIP {}".format(current_eip['PublicIp']))
        try:
            self.ec2_client.disassociate_address(
                AssociationId=current_eip['AssociationId']
            )
            self.ec2_client.create_tags(
                Resources=[current_eip['AllocationId']],
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

    def postfix_service(self, cmd):
        """
        Run SSM Command to Start or Stop the Postfix Service.
        """
        logger.info("Executing {} Postfix SSM Document, for Instance Id: {}".format(cmd, self.instance.id))
        try:
            ssmresponse = self.ssm.send_command(
                InstanceIds=[self.instance.id],
                DocumentName=ssm_postfix_service,
                Parameters={'cmd': [cmd]}
            )
            time.sleep(1)
            waiter = self.ssm.get_waiter('command_executed')
            waiter.wait(
                CommandId=ssmresponse['Command']['CommandId'],
                InstanceId=self.instance.id
            )
        except ClientError as e:
            logger.exception("Unable to send SSM command. {}".format(e))
            return False
        except WaiterError as we:
            logger.exception("Waiter max attempts exceeded. {}".format(we))
            return False
        return True


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
                    'CloudEmail:warmup-delivery:*'
                ]
            }
        ]
    )
    return instances


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
        multi_eip = MultiEip(instance_id)
        if multi_eip.fetch_private_ips() is not None:
            if multi_eip.postfix_service('stop'):
                logger.info("Successfully stopped Postfix service.")
                if multi_eip.associate_multi_eips():
                    logger.info("===FINISHED=== Rotating SSM Delivery Multi EIP's.")
                if multi_eip.postfix_service('start'):
                    logger.info("Successfully started Postfix service.")
                else:
                    logger.error("Unable to start Postfix Service on Instance: {}.".format(instance_id))
            else:
                logger.error("Unable to stop Postfix Service on Instance: {}.".format(instance_id))

    elif 'EC2InstanceId' in event['detail']:
        logger.info("Lambda Function triggered from Instance Launching Lifecycle Hook.")
        instance_id = event['detail']['EC2InstanceId']
        autoscaling_group_name = event['detail']['AutoScalingGroupName']
        lifecycle_hook_name = event['detail']['LifecycleHookName']
        lifecycle_action_token = event['detail']['LifecycleActionToken']
        lifecycle_action_result = 'ABANDON'

        multi_eip = MultiEip(instance_id)
        if multi_eip.assign_private_ips():
            if multi_eip.fetch_private_ips() is not None:
                if multi_eip.associate_multi_eips():
                    logger.info("Completing lifecycle action with CONTINUE")
                    lifecycle_action_result = 'CONTINUE'
        else:
            logger.error("Completing lifecycle action with ABANDON")

        return complete_lifecycle_action(
            autoscaling_group_name,
            lifecycle_hook_name,
            lifecycle_action_token,
            lifecycle_action_result
        )
    else:
        logger.info("Lambda Function triggered from CloudWatch Scheduled Event for multi-EIP Rotation.")
        for instance in get_instances_by_name():
            if (datetime.now(instance.launch_time.tzinfo) - instance.launch_time).total_seconds() <= 1800:
                logger.info("Instance Id: {} was recently deployed. Skipping".format(instance.id))
                continue
            multi_eip = MultiEip(instance.id)
            if multi_eip.fetch_private_ips() is not None:
                if multi_eip.postfix_service('stop'):
                    logger.info("Successfully stopped Postfix service.")
                    if multi_eip.associate_multi_eips():
                        logger.info("===FINISHED=== Rotating ALL Delivery Multi EIP's.")
                    if multi_eip.postfix_service('start'):
                        logger.info("Successfully started Postfix service.")
                    else:
                        logger.error("Unable to start Postfix Service on Instance: {}.".format(instance.id))
                else:
                    logger.error("Unable to stop Postfix Service on Instance: {}.".format(instance.id))
