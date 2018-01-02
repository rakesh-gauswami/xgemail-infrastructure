#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Get the EC2 Instance Id from the AMI CloudFormation Stack and get the console output.
Print it and save as a file to add as an artifact.
"""

import argparse
import boto3
import time
import os
import botocore


# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(description="Get Ec2 Instance Console Output.")
    parser.add_argument("--resource", "-r", dest='resource', default='XgemailServerInstance', help="The LogicalResourceId in the CloudFormation stack for the EC2 Instance.")
    return parser.parse_args()


def main():
    args = parse_command_line()
    # Set your AWS creds if you aren't using a dotfile or some other boto auth method
    aws_access_key_id = os.environ['bamboo_custom_aws_accessKeyId']
    aws_secret_access_key = os.environ['bamboo_custom_aws_secretAccessKey_password']
    aws_session_token = os.environ['bamboo_custom_aws_sessionToken_password']
    region = os.environ['bamboo_REGION']
    plan = os.environ['bamboo_shortPlanKey']
    build = os.environ['bamboo_buildNumber']
    stack_name = os.environ['bamboo_custom_aws_cfn_stack_resources']
    print 'Stack Name: %s' % stack_name
    session = boto3.Session(aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key, aws_session_token=aws_session_token, region_name=region)
    # region = os.environ['AWS_DEFAULT_REGION'] # Use for running outside of Bamboo
    # session = boto3.Session(region_name=region) # Option A for running outside of Bamboo
    # session = boto3.Session(profile_name='inf',region_name='eu-central-1') # Option B for running outside of Bamboo
    # session = boto3.Session(aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key) # Option C for running outside of Bamboo
    cf_resource = session.resource('cloudformation')
    ec2_client = session.client('ec2')
    # Using the CloudFormation Stack name derive the Instance Id from the Logical Resource ID.
    try:
        stack_resource = cf_resource.StackResource(stack_name=stack_name, logical_id=args.resource)
        ec2_instance = stack_resource.physical_resource_id
        print "EC2 Instance Id: %s" % ec2_instance
        console_output = ec2_client.get_console_output(InstanceId=ec2_instance)['Output']
        print console_output
        f = open('console_output.txt', 'w+')
        f.write(console_output)
        f.close()
    except botocore.exceptions.ClientError as e:
        print e.response['Error']['Code']


if __name__ == "__main__":
    main()