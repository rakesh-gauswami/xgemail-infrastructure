#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
This script is used to terminate Xgemail Ec2 Instances.
This script deals with the termination of Ec2 Instances in Xgemail AutoScaling Groups, and monitoring the full termination of the instance.
Xgemail Ec2 Instances need to use persistent Ebs volumes. Current Infrastructure Scaling is done manually.
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
from botocore.exceptions import ClientError, WaiterError


# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(description="Terminate Ec2 Instances for given Instance type.")
    parser.add_argument("--term", "-t", dest='termination_control', default=False, nargs='+', help="Enter the max number of instances to terminate at once.")
    parser.add_argument("--itype", "-i", dest='itype', choices=['submit', 'delivery', 'xdelivery', 'customer-submit', 'internet-delivery', 'internet-xdelivery'], help="Enter the Instance type.")
    return parser.parse_args()


class XgemailInstance(object):
    def __init__(self, instance, ami, build):
        tags = {tag['Key']: tag['Value'] for tag in instance.tags}
        self.current_ami = ami
        self.current_build_result_key = build
        self.image_id = instance.image_id
        self.instance_id = instance.instance_id
        self.asg = tags.get('aws:autoscaling:groupName')
        self.build_result_key = tags.get('BuildResultKey')
        self.bundle_version = tags.get('BundleVersion')
        self.tags = instance.tags
        self.terminate = self.build_check()
        self.elb = self.get_elb()

    def build_check(self):
        if self.current_ami not in self.image_id or self.current_build_result_key not in self.build_result_key:
            return True
        else:
            return False

    def terminate_asg_instance(self):
        print('===>    Terminate instance')
        terminate_response = asg_client.terminate_instance_in_auto_scaling_group(InstanceId=self.instance_id, ShouldDecrementDesiredCapacity=False)
        print terminate_response

    def get_new_instance(self):
        for asg in asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[self.asg], MaxRecords=1)['AutoScalingGroups']:
            self.instance_id = asg['Instances'][0]['InstanceId']

    def get_elb(self):
        for elb in asg_client.describe_load_balancers(AutoScalingGroupName=self.asg, MaxRecords=1)['LoadBalancers']:
            return elb['LoadBalancerName']


def get_instances(name):
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


if __name__ == "__main__":
    args = parse_command_line()
    # Set your AWS creds if you aren't using a dotfile or some other boto auth method
    aws_access_key_id = os.environ['bamboo_custom_aws_accessKeyId']
    aws_secret_access_key = os.environ['bamboo_custom_aws_secretAccessKey_password']
    aws_session_token = os.environ['bamboo_custom_aws_sessionToken_password']
    region = os.environ['bamboo_vpc_REGION']
    build_result_key = os.environ['bamboo_buildResultKey']
    ami_id = os.environ['bamboo_xgemail_ami_id']
    termination_control = args.termination_control
    session = boto3.Session(aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key, region_name=region)

    ec2 = session.resource('ec2')
    """:type: pyboto3.ec2 """
    ec2_client = ec2.meta.client
    """:type: pyboto3.ec2 """
    asg_client = session.client('autoscaling')
    """:type: pyboto3.autoscaling """
    elb_client = session.client('elb')
    """:type: pyboto3.elb """

    termination_queue = list()
    running_queue = list()
    instance_type = 'CloudEmail:' + args.itype + ':*'
    elb_name = ''

    while True:
        instances = get_instances(name=instance_type)
        xinstances = list()
        for i in instances:
            xi = XgemailInstance(instance=i, ami=ami_id, build=build_result_key)
            elb_name = xi.elb
            xinstances.append(xi)
        for x in xinstances:
            if x.terminate:
                print x.instance_id
                x.terminate_asg_instance()
                termination_queue.append(x)
        ec2_client.get_waiter('instance_terminated').wait(
            InstanceIds=[i.instance_id for i in termination_queue],
            WaiterConfig={
                'Delay': 10,
                'MaxAttempts': 100
            })
        print('===>    Instances terminated')
        for x in termination_queue:
            x.get_new_instance()
        ec2_client.get_waiter('instance_running').wait(
            InstanceIds=[i.instance_id for i in termination_queue],
            WaiterConfig={
                'Delay': 10,
                'MaxAttempts': 100
            }
        )
        time.sleep(5)
        print('===>    Instances running')
        ec2_client.get_waiter('instance_status_ok').wait(
            InstanceIds=[i.instance_id for i in termination_queue],
            WaiterConfig={
                'Delay': 15,
                'MaxAttempts': 100
            }
        )
        print('===>    Instances status OK')
        for x in termination_queue:
            running_queue.append({'InstanceId': x.instance_id})
        elb_client.get_waiter('instance_in_service').wait(
            LoadBalancerName=elb_name,
            Instances=running_queue,
            WaiterConfig={
                'Delay': 60,
                'MaxAttempts': 100
            }
        )
        print('===>    Instances in service')
        break
