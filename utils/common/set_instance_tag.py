#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Set tag on the current instance.
"""

import boto3
import optparse

import sophos_common


def parse_command_line():
    parser = optparse.OptionParser(
            description="Set a tag for the current EC2 instance.",
            usage="%prog [options] NAME VALUE")

    options, args = parser.parse_args()

    if len(args) < 2:
        parser.error("missing required arguments")

    if len(args) > 2:
        parser.error("too many arguments")

    name = args[0]

    value = args[1]

    return options, name, value


def main():
    options, name, value = parse_command_line()

    region = sophos_common.aws_region()

    instance_id = sophos_common.aws_instance_id()

    ec2 = boto3.client('ec2', region_name=region)

    sophos_common.boto3_check(ec2.create_tags, Resources=[instance_id], Tags=[{"Key": name, "Value": value}])

if __name__ == "__main__":
    main()
