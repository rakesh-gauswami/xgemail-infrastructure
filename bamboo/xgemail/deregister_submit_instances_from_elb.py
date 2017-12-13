#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Deregisters Xgemail submit instances with a specific tag from their respective
load balancer.
"""

import boto3
import optparse
import sys

try:
    import sophos.aws
except ImportError as e:
    print >> sys.stderr, e
    print >> sys.stderr, "Wrap this command with bamboo/pywrap.py to update PYTHONPATH."

def _main():
    parser = optparse.OptionParser(
        usage="%prog <region>"
    )
    options, args = parser.parse_args()
    if len(args) < 1:
        parser.error("too few arguments")
    if len(args) > 1:
        parser.error("too many arguments")

    region = args[0]

    session = boto3.Session()

    aws = sophos.aws.AwsHelper(session=session, region=region)

    ec2 = aws.client("ec2")
    elb = aws.client("elb")
    as_client = aws.client("autoscaling")

    instances_info = filter_instances(
        'CloudEmail:ShouldTerminate',
        'true',
        ec2
    )

    instances = instances_info['Instances']
    autoscaling_group_name = instances_info['AutoScalingGroupName']

    submit_loadbalancer = retrieve_submit_loadbalancer(
        autoscaling_group_name,
        as_client
    )

    deregister_submit_instances_from_elb(
        instances,
        submit_loadbalancer,
        elb
    )

def filter_instances(tag_name, tag_value, ec2):
    print 'Filtering instances by tag <%s=%s>' % (tag_name, tag_value)

    if not tag_name.startswith('tag:'):
        tag_name = 'tag:' + tag_name

    instances = []
    response = ec2.describe_instances(
        Filters = [
            {
                'Name': tag_name,
                'Values': [tag_value]
            }
        ]
    )

    autoscaling_group = None

    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']

            # skip instances that are not in a running state
            if instance['State']['Code'] != 16:
                print 'Instance <%s> is not running, skipping it.' % \
                    (instance_id)
                continue

            if autoscaling_group == None:
                for tag in instance['Tags']:
                    if tag['Key'] == 'aws:autoscaling:groupName':
                        autoscaling_group = tag['Value']
                        break
            instances.append({'InstanceId': instance_id})
    return {
        'Instances': instances,
        'AutoScalingGroupName': autoscaling_group
    }

def retrieve_submit_loadbalancer(autoscaling_group_name, as_client):
    print 'Retrieving submit loadbalancer for autoscaling group name <%s>' % \
        (autoscaling_group_name)

    autoscaling_response = as_client.describe_auto_scaling_groups(
        AutoScalingGroupNames = [autoscaling_group_name]
    )

    return autoscaling_response['AutoScalingGroups'][0]['LoadBalancerNames'][0]

def deregister_submit_instances_from_elb(instances, submit_loadbalancer, elb):
    print 'Deregistering instances <%s> from ELB <%s>' % \
        (instances, submit_loadbalancer)

    elb.deregister_instances_from_load_balancer(
        LoadBalancerName = submit_loadbalancer,
        Instances = instances
    )

if __name__ == "__main__":
    _main()
