#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Add a tag to a specific set of instances. The instances are selected by a
filter which is provided through an option argument.
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
        usage="%prog <region> <instance-tag-filter> <tag-name> <tag-value>"
    )
    options, args = parser.parse_args()

    if len(args) < 4:
        parser.error("too few arguments")
    if len(args) > 4:
        parser.error("too many arguments")

    region = args[0]
    instance_tag_filter = args[1]
    tag_name = args[2]
    tag_value = args[3]

    session = boto3.Session()

    aws = sophos.aws.AwsHelper(session=session, region=region)

    ec2 = aws.client("ec2")

    all_instances = find_instances_by_tag(
        instance_tag_filter,
        ec2
    )

    filtered_instances = filter_tag_requirement(
        all_instances,
        ec2
    )

    add_tag_to_instances(
        filtered_instances,
        tag_name,
        tag_value,
        ec2
    )

def find_instances_by_tag(tag_name_filter_value, ec2):
    print 'Filtering instances by tag value: <%s>' % (tag_name_filter_value)

    instances = []

    response = ec2.describe_instances(
        Filters = [{'Name': 'tag:Name', 'Values': [tag_name_filter_value]}]
    )

    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']

            # skip instances that are not in a running state
            if instance['State']['Code'] != 16:
                print 'Instance <%s> is not running, skipping it.' % \
                    (instance_id)
                continue

            instances.append(instance['InstanceId'])
    return instances

def filter_tag_requirement(all_instances, ec2):
    filtered_instances = []

    if not all_instances:
        return filtered_instances

    for instance_id in all_instances:
        # we first need to retrieve the VolumeId for the current instance
        instance_response = ec2.describe_instance_attribute(
            InstanceId = instance_id,
            Attribute = 'blockDeviceMapping'
        )

        block_device_mappings = instance_response['BlockDeviceMappings']
        volume_id = None
        for block_device in block_device_mappings:
            if block_device['DeviceName'] == '/dev/xvdi':
                volume_id = block_device['Ebs']['VolumeId']
                break

        if not volume_id:
            print 'Unable to retrieve volume_id for instance id <%s>' % \
                (instance_id)
            sys.exit(1)

        volume_response = ec2.describe_volumes(
            VolumeIds = [volume_id]
        )

        volumes = volume_response['Volumes']

        if len(volumes) <= 0:
            print 'Unable to describe volume for volume id <%s>' % (volume_id)
            sys.exit(1)

        # we are only interested in instance id's with an Iops setting of 100
        iops_setting = volumes[0]['Iops']
        if iops_setting != 100:
            print 'instance_id <%s> has an Iops setting of <%d>, skipping.' % \
                (instance_id, iops_setting)
            continue
        filtered_instances.append(instance_id)
    return filtered_instances

def add_tag_to_instances(instances, tag_name, tag_value, ec2):
    print 'Tagging instances <%s> with %s=%s' % (instances, tag_name, tag_value)

    ec2.create_tags(
        Resources = instances,
        Tags = [{'Key': tag_name, 'Value': tag_value}]
    )

if __name__ == "__main__":
    _main()
