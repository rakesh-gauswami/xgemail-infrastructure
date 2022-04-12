#!/usr/bin/env python3
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2020, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
This script is used to terminate Xgemail Ec2 Instances.
This script deals with the termination of Ec2 Instances in Xgemail AutoScaling Groups, and monitoring the full termination of the instance.
Xgemail Ec2 Xdelivery Instances need to use persistent Ebs volumes. Current Infrastructure Scaling is done manually.
For every 1 EC2 instance and its associated Ebs Volume there is 1 AutoScaling Group and they are all part of 1 CloudFormation Stack.
1 CloudFormation Stack -> 1 AutoScaling Group -> 1 Ec2 Instance -> 1 Ebs Volume
After a CloudFormation Stack update this script will run in the following order.
1. Gather all the instances from a given type of Xgemail instances
2. Determine which instances are out of date and need to be cycled.
3. Terminate the instance in each AutoScaling Group.
4. Wait for termination to complete.
5. Gather new instance ids from each AutoScaling Group.
6. Wait for Instances to become "Running".
7. Wait for status to be OK.
8. Wait for associated ELB state to be "In Service"
Else it will fail, causing the Bamboo step to fail.
"""

import argparse
import boto3
import os
import time
import logging
from botocore.exceptions import ClientError, WaiterError

# logging to console setup
if os.environ.get('BOTO_LOG_LEVEL') is None:
    logging.getLogger('botocore').setLevel(logging.WARN)
    logging.getLogger('boto3').setLevel(logging.WARN)
else:
    logging.getLogger('botocore').setLevel(logging.getLevelName(os.environ.get('BOTO_LOG_LEVEL').strip()))
    logging.getLogger('boto3').setLevel(logging.getLevelName(os.environ.get('BOTO_LOG_LEVEL').strip()))

logger = logging.getLogger('xdelivery-instance-cycle')
if os.environ.get('LOG_LEVEL') is None:
    logger.setLevel('INFO')
else:
    logger.setLevel(logging.getLevelName(os.environ.get('LOG_LEVEL').strip()))
console_handler = logging.StreamHandler()
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)


# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(description="Terminate Ec2 Instances for given Xdelivery Instance type.")
    parser.add_argument("--itype", "-i", dest='itype', required=True, choices=['xdelivery', 'customer-xdelivery', 'internet-xdelivery', 'risky-xdelivery', 'warmup-xdelivery', 'beta-xdelivery', 'delta-xdelivery', 'mf-inbound-xdelivery', 'mf-outbound-xdelivery' ], help="Enter the Instance type.")
    parser.add_argument("--term", "-t", dest='termination_control', type=int, default=1, help="Enter the max number of instances to terminate at once.")
    parser.add_argument("--region", "-r", dest='region', help="Valid supported region", required=True)
    parser.add_argument("--build", "-b", dest='build_tag', help="build tag", required=True)
    parser.add_argument("--number", "-n", dest='build_number', type=int, required=True, help="Enter the Jenkins build number.")
    parser.add_argument("--ami", "-a", dest='ami_id', help="ami-id", required=True)
    return parser.parse_args()


class XgemailInstance(object):
    def __init__(self, instance, ami, build_tag, build_number):
        tags = {tag['Key']: tag['Value'] for tag in instance.tags}
        self.current_ami = ami
        self.current_build_tag = build_tag
        self.current_build_number = build_number
        self.image_id = instance.image_id
        self.instance_id = instance.instance_id
        self.asg = tags.get('aws:autoscaling:groupName')
        self.build_tag = tags.get('BuildTag')
        self.bundle_version = tags.get('BundleVersion')
        self.tags = instance.tags
        self.terminate = self.build_check()
        self.elb = None

    def build_check(self):
        """
        Compares the tags of the EC2 instance to the values from the deployment.
        """
        logger.debug("current_ami: {}, image_id: {}, current_build_tag: {}, build_tag: {}"
                     .format(self.current_ami, self.image_id, self.current_build_tag, self.build_tag))
        if self.current_ami not in self.image_id or self.current_build_tag not in self.build_tag:
            return True
        else:
            return False

    def terminate_asg_instance(self):
        """
        Terminate the EC2 Instance through the AutoScaling Group to allow the lifecycle hook to run.
        """
        logger.info('===>    Terminate instance')
        try:
            terminate_response = asg_client.terminate_instance_in_auto_scaling_group(InstanceId=self.instance_id, ShouldDecrementDesiredCapacity=False)
            logger.info(terminate_response)
        except ClientError as ce:
            logger.exception("Client Error terminating the ASG Instance. {}".format(ce))

    def get_new_instance(self):
        """
        After termination this is run to get the new EC2 Instance Id from the AutoScaling Group.
        """
        terminated = self.instance_id

        while self.instance_id == terminated:
            try:
                for asg in asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[self.asg], MaxRecords=1)['AutoScalingGroups']:
                    for i in asg['Instances']:
                        if i['InstanceId'] != self.instance_id:
                            self.instance_id = i['InstanceId']
                            break
                    self.elb = asg['LoadBalancerNames'][0]
                    logger.info('===>    New Instance ID: {}'.format(self.instance_id))
            except ClientError as ce:
                logger.exception("Client Error describing AutoScaling Groups. {}".format(ce))


def get_instances(name):
    """
    Find Instances based on their Xgemail Instance type, which is in their name.
    """
    filters = [
        {
            'Name': 'tag:Name',
            'Values': [name]
        },
        {
            'Name': 'instance-state-name',
            'Values': ['running']
        }
    ]
    return ec2.instances.filter(Filters=filters)


def termination_control(l, n):
    """
    Enables the termination queue to be worked on in a configurable number of chunks as opposed to all at once.
    """
    for i in range(0, len(l), n):
        yield l[i:i + n]


def wait_for_instance_terminated(instance_list):
    """
    EC2 Waiter that waits for a list of Instances to be terminated before moving on.
    """
    try:
        ec2_client.get_waiter('instance_terminated').wait(
            InstanceIds=[i.instance_id for i in instance_list],
            WaiterConfig={
                'Delay': delay_default,
                'MaxAttempts': max_attempts_default
            })
    except WaiterError as we:
        logger.exception("Waiter Error instance_terminated. {}".format(we))
        return False

    return True


def wait_for_instance_running(instance_list):
    """
    EC2 Waiter that waits for a list of Instances to be in running state before moving on.
    """
    time.sleep(5)
    try:
        ec2_client.get_waiter('instance_running').wait(
            InstanceIds=[i.instance_id for i in instance_list],
            WaiterConfig={
                'Delay': delay_default,
                'MaxAttempts': max_attempts_default
            }
        )
    except WaiterError as we:
        logger.exception("Waiter Error instance_running. {}".format(we))
        return False

    return True


def wait_for_instance_status_ok(instance_list):
    """
    EC2 Waiter that waits for a list of Instances to be in OK status before moving on.
    """
    time.sleep(5)
    try:
        ec2_client.get_waiter('instance_status_ok').wait(
            InstanceIds=[i.instance_id for i in instance_list],
            WaiterConfig={
                'Delay': delay_default,
                'MaxAttempts': max_attempts_default
            }
        )
    except WaiterError as we:
        logger.exception("Waiter Error instance_status_ok. {}".format(we))
        return False

    return True


def wait_for_instance_in_service(instance_list):
    """
    ELB Waiter that waits for a list of Instances to be in service before moving on.
    """
    time.sleep(5)
    try:
        elb_client.get_waiter('instance_in_service').wait(
            LoadBalancerName=elb_name,
            Instances=[{'InstanceId': i.instance_id} for i in instance_list],
            WaiterConfig={
                'Delay': delay_instance_in_service,
                'MaxAttempts': max_attempts_default
            }
        )
    except WaiterError as we:
        logger.exception("Waiter Error instance_in_service. {}".format(we))
        return False

    return True


if __name__ == "__main__":
    args = parse_command_line()
    # Set your AWS creds if you aren't using a dotfile or some other boto auth method
    session = boto3.Session(region_name=args.region)

    ec2 = session.resource('ec2')
    """:type: pyboto3.ec2 """
    ec2_client = ec2.meta.client
    """:type: pyboto3.ec2 """
    asg_client = session.client('autoscaling')
    """:type: pyboto3.autoscaling """
    elb_client = session.client('elb')
    """:type: pyboto3.elb """

    max_attempts_default = 100
    delay_default = 30
    delay_instance_in_service = 120
    termination_queue = list()
    instance_type = 'email:' + args.itype + ':*'
    elb_name = ''

    while True:
        instances = get_instances(name=instance_type)
        xinstances = list()
        for i in instances:
            xi = XgemailInstance(instance=i, ami=args.ami_id, build_tag=args.build_tag, build_number=args.build_number)
            logger.debug("Found Instance: {}".format(xi.instance_id))
            xinstances.append(xi)
        termination_queue = [x for x in xinstances if x.terminate]
        while len(termination_queue) != 0:
            logger.debug("Instances in termination queue: {}".format(len(termination_queue)))
            for tq in list(termination_control(termination_queue, args.termination_control)):
                for x in tq:
                    x.terminate_asg_instance()
                if wait_for_instance_terminated(tq):
                    logger.info("===>    Instances terminated")
                    for x in tq:
                        x.get_new_instance()
                    elb_name = tq[0].elb
                    if wait_for_instance_running(tq):
                        logger.info("===>    Instances running")
                        if wait_for_instance_status_ok(tq):
                            logger.info("===>    Instances status OK")
                            if wait_for_instance_in_service(tq):
                                logger.info("===>    Instances in service")
                            else:
                                logger.error("===>    Instances NOT in service")
                                exit(1)
                        else:
                            logger.error("===>    Instances status NOT OK")
                            exit(1)
                    else:
                        logger.error("===>    Instances NOT running")
                        exit(1)

            break
        break
    logger.info("Cycling Xdelivery Instances Complete!")
