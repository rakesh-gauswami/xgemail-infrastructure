#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Set DeleteOnTermination on the current instance
"""

import boto3

import sophos_common


if __name__ == '__main__':

    region = sophos_common.aws_region()
    instance_id = sophos_common.aws_instance_id()
    device = '/dev/xvdi'

    # Create EC2 Resource
    ec2 = boto3.resource('ec2', region_name=region)

    instance = ec2.Instance(instance_id)
    instance.modify_attribute(
        BlockDeviceMappings=[
            {
                'DeviceName': device,
                'Ebs': {
                    'DeleteOnTermination': False
                }
            }
        ]
    )
