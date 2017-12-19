#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
This script will run in a build plan triggered after Java ALL Deploy to send a JSON object
to an SQS queue. This queue is being monitored by a service which will in turn trigger the
nightly automation tests.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import boto3
import optparse


def parse_command_line():
    parser = optparse.OptionParser(
        usage="%prog ACCOUNT ACCOUNT_REGION_VPCS BUILD_NUMBER REGION VPC_NAME QUEUE_URL")

    options, args = parser.parse_args()

    if len(args) != 6:
        parser.error("incorrect number of arguments")

    account = args[0]
    account_region_vpcs = args[1]
    build_number = args[2]
    region = args[3]
    vpc_name = args[4]
    queue_url = args[5]

    return account, account_region_vpcs, build_number, region, vpc_name, queue_url


def send_message_to_nightly_trigger_queue(account, account_region_vpcs, build_number, region, vpc_name, queue_url):
    client = boto3.client('sqs', region_name="us-west-2")
    message_body = "{" \
                   "\"account\":\"" + account + "\"," \
                   "\"account_region_vpcs\":\"" + account_region_vpcs + "\"," \
                   "\"build_number\":\"" + build_number + "\"," \
                   "\"region_vpc\":\"" + region + "/" + vpc_name + "\"" \
                   "}"

    try:
        client.send_message(
            QueueUrl=queue_url,
            MessageBody=message_body
        )
    except Exception as e:
        raise e


def main():
    account, account_region_vpcs, build_number, region, vpc_name, queue_url = parse_command_line()
    send_message_to_nightly_trigger_queue(account, account_region_vpcs, build_number, region, vpc_name, queue_url)


if __name__ == "__main__":
    main()
