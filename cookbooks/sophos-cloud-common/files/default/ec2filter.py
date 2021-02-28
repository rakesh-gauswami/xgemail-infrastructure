#!/usr/bin/env python
# vim: autoindent expandtab shiftwidth=4 filetype=python

"""
Filter input, replacing EC2 instance hostnames and IP addresses with their Name tags.
"""

import fileinput
import os
import re
import signal
import subprocess
import sys

import boto3


def get_ec2_client():
    output = subprocess.check_output(["/opt/aws/bin/ec2-metadata", "-z"])
    az = output.strip().split()[1]
    region = az[0:-1]
    ec2_client = boto3.client("ec2", region_name=region)
    return ec2_client


def get_replacement_dicts(ec2_client):
    replacement_dicts = {
        "addrs": dict(),
        "hosts": dict(),
    }

    ip_name_dict = dict()

    next_token = None
    while True:
        if next_token is None:
            response = ec2_client.describe_instances()
        else:
            response = ec2_client.describe_instances(NextToken=next_token)

        for reservation in response.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                # Get name from Name tag, default to instance id.
                name = instance["InstanceId"]
                for tag in instance.get("Tags", []):
                    if tag["Key"] == "Name":
                        name = tag["Value"]

                private_dns_name = instance.get("PrivateDnsName", "")
                if private_dns_name != "":
                    replacement_dicts["hosts"][private_dns_name] = name

                private_ip = instance.get("PrivateIpAddress", "")
                if private_ip != "":
                    replacement_dicts["addrs"][private_ip] = name

                public_ip = instance.get("PublicIpAddress", "")
                if public_ip != "":
                    replacement_dicts["addrs"][public_ip] = name

        next_token = response.get("NextToken")
        if next_token is None:
            break

    return replacement_dicts


def process(ec2_client, replacement_dicts, line):
    line = re.sub(
            r"\d+(\.\d+){3}",
            lambda match: replacement_dicts["addrs"].get(match.group(), match.group()),
            line)

    for host, name in replacement_dicts["hosts"].items():
        line = line.replace(host, name)

    sys.stdout.write(line)


def main():
    if len(sys.argv) > 1 and sys.argv[1] in ["-h", "--help"]:
        print "%s: %s" % (sys.argv[0], __doc__.strip().splitlines()[0])
        sys.exit(0)

    ec2_client = get_ec2_client()

    replacement_dicts = get_replacement_dicts(ec2_client)

    for line in fileinput.input():
        process(ec2_client, replacement_dicts, line)


if __name__ == "__main__":
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(128 + signal.SIGINT)
