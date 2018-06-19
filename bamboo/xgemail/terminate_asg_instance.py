#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
This script is part 1 of 2 Bamboo Script steps used to terminate Xgemail Ec2 Instances.
This script deals with the termination of Ec2 Instances in Xgemail AutoScaling Groups, and monitoring the full termination of the instance.
This step was separated as its own Bamboo Script step to better separate the processes within Bamboo. (Termination & Creation)
Xgemail Ec2 Instances need to use persistent Ebs volumes. Current Infrastructure Scaling is done manually.
For every 1 EC2 instance and its associated Ebs Volume there is 1 AutoScaling Group and they are all part of 1 CloudFormation Stack.
1 CloudFormation Stack -> 1 AutoScaling Group -> 1 Ec2 Instance -> 1 Ebs Volume
After a CloudFormation Stack update this script will run and gather the AutoScaling Group name from the CloudFormation Stack Resource.
Next Using the AutoScaling Group name it will then find the instance id of the single instance in the AutoScaling Group.
It will then terminate the single instance in the AutoScaling Group.
Last use the termination response to monitor the AutoScaling Activity to ensure that the instance was properly terminated.
Else it will fail, causing the Bamboo step to fail.
"""

import argparse
import boto3
import time
import os
import botocore


# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(description="Terminate Ec2 Instance in given AutoScaling Group.")
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
    cf_resource = session.resource('cloudformation')
    asg_client = session.client('autoscaling')
    # Using the CloudFormation Stack name derive the AutoScaling Group name from the Logical Resource ID.
    for stack_name in cfn_stacks:
        try:
            stack_resource = cf_resource.StackResource(stack_name=stack_name, logical_id=args.resource)
            asg_name = stack_resource.physical_resource_id
            print "AutoScalingGroupName: %s" % asg_name

            # Using the AutoScaling Group get the instance-id and terminate the instance in the AutoScaling Group.
            # Use the Activity that is passed back to monitor the status of the operation.
            for asg in asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name], MaxRecords=1)['AutoScalingGroups']:
                instance_id = asg['Instances'][0]['InstanceId']
                print "InstanceId: %s" % instance_id
                terminate_response = asg_client.terminate_instance_in_auto_scaling_group(InstanceId=instance_id, ShouldDecrementDesiredCapacity=False)['Activity']
                progress = terminate_response['Progress']
                status_code = terminate_response['StatusCode']
                print "ActivityId: %s"              % terminate_response['ActivityId']
                print "StatusCode: %s"              % status_code
                print "Progress: %s"                % progress

                # Keep checking the AutoScaling Activity until the progress equals 100 and the Status is Successful.
                while progress != 100 and status_code != 'Successful':
                    time.sleep(60)
                    activities = asg_client.describe_scaling_activities(ActivityIds=[terminate_response['ActivityId']], MaxRecords=1)['Activities']
                    progress = activities[0]['Progress']
                    status_code = activities[0]['StatusCode']
                    print "Description: %s" % activities[0]['Description']
                    print "Progress: %s"    % progress
                    print "StatusCode: %s"  % status_code
                print "Instance %s has been terminated." % instance_id
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] == 'Throttling':
                time.sleep(60)
                pass
            else:
                raise e


if __name__ == "__main__":
    main()
