#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
This script is part 2 of 2 Bamboo Script steps used to terminate Xgemail EC2 Instances.
This script deals with the creation of Ec2 Instances in Xgemail AutoScaling Groups, and monitoring the full creation of the instance.
This step was separated as its own Bamboo Script step to better separate the processes within Bamboo. (Termination & Creation)
It will be easier to determine where a build plan failure occurred.
After the Part 1 termination script runs successfully this script will run and gather the AutoScaling Group name from the CloudFormation Stack Resource.
Next Using the AutoScaling Group name it will then find the new instance id of the single instance in the AutoScaling Group.
Using the AutoScaling Group name it will wait until the AutoScaling Group's Lifecycle State is InService.
Next, Using the instance-id it will continually check the instances' state and status until State is running and Status is Passed.
"""

import argparse
import boto3
import time
import os


# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(description="Verify creation of Ec2 Instance in given AutoScaling Group.")
    parser.add_argument("--resource", "-r", dest='resource', default='JavaAutoScalingGroup', choices=['JavaAutoScalingGroup', 'XgemailAutoScalingGroup', 'ElasticSearchAutoScalingGroup'], help="The LogicalResourceId in the CloudFormation stack for the AutoScaling Group.")
    parser.add_argument("--asg", "-a", dest='asg', default=False, nargs='+', help="Enter one or more AutoScaling Group Names.")

    return parser.parse_args()


def main():

    args = parse_command_line()
    # Set your AWS creds if you aren't using a dotfile or some other boto auth method
    aws_access_key_id = os.environ['bamboo_custom_aws_accessKeyId']
    aws_secret_access_key = os.environ['bamboo_custom_aws_secretAccessKey_password']
    aws_session_token = os.environ['bamboo_custom_aws_sessionToken_password']
    region = os.environ['bamboo_vpc_REGION']
    session = boto3.Session(aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key, aws_session_token=aws_session_token, region_name=region)
    # region = os.environ['AWS_DEFAULT_REGION'] # Use for running outside of Bamboo
    # session = boto3.Session(region_name=region) # Option A for running outside of Bamboo
    # session = boto3.Session(profile_name='inf',region_name='eu-central-1') # Option B for running outside of Bamboo
    # session = boto3.Session(aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key) # Option C for running outside of Bamboo
    # Add the names of the associated CloudFormation Stack(s) to perform termination on.
    cfn_stacks = args.asg
    cf_client = session.client('cloudformation')
    asg_client = session.client('autoscaling')
    ec2_client = session.client('ec2')

    # Get the Ec2 Instances State and Status.
    def describe_instance_status(instance):
        return ec2_client.describe_instance_status(InstanceIds=[instance])['InstanceStatuses'][0]

    # Using the CloudFormation Stack name derive the AutoScaling Group name from the Logical Resource ID.
    for stack_name in cfn_stacks:
        stack_resource = cf_client.describe_stack_resource(StackName=stack_name, LogicalResourceId=args.resource)
        asg_name = stack_resource['StackResourceDetail']['PhysicalResourceId']
        print "AutoScalingGroupName: %s" % asg_name

        # Check the status of the AutoScaling Group and get the new instance-id
        for asg in asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name], MaxRecords=1)['AutoScalingGroups']:
            instance_id = asg['Instances'][0]['InstanceId']
            lifecycle_state = asg['Instances'][0]['LifecycleState']
            health_status = asg['Instances'][0]['HealthStatus']
            print "InstanceId: %s"      % instance_id
            print "LifecycleState: %s"  % lifecycle_state
            print "HealthStatus: %s"    % health_status

            # Keep checking Lifecycle State until it equals InService
            while lifecycle_state != 'InService':
                time.sleep(5)
                lifecycle_state = asg_client.describe_auto_scaling_instances(InstanceIds=[instance_id], MaxRecords=1)['AutoScalingInstances'][0]['LifecycleState']
                print "LifecycleState: %s" % lifecycle_state
            print "AutoScalingGroup is InService. Now getting Instance Status"
            instance_state = ''
            instance_status = ''

            # Using the describe_instance_status function, continually check the instances' state and status until State is running and Status is Passed.
            while not (instance_state == 'running' and instance_status == 'passed'):
                time.sleep(10)
                ec2_status = describe_instance_status(instance_id)
                instance_state = ec2_status['InstanceState']['Name']
                instance_status = ec2_status['InstanceStatus']['Details'][0]['Status']
                print "InstanceState: %s - InstanceStatus: %s" % (instance_state, instance_status)
            print "Instance Deployment Complete!"

if __name__ == "__main__":
    main()

