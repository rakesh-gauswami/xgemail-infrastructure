#!/usr/bin/env python
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# common/register_new_ami.py:
#   register new ami from root volume snapshot

import argparse
import boto3
import copy
import json
import logging
import sys

from sophos_common import *


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
            "settings_file",
            help="python file containg configuration setting assignments")

    parser.add_argument(
            "region",
            help="destination region")

    parser.add_argument(
            "snapshot_id",
            help="source snapshot id (found in region specified in settings.py)")

    parser.add_argument(
            "parent_ami_json",
            help="JSON representation of parent AMI")

    parser.add_argument(
            "output_path",
            help="file to write image info to")

    return parser.parse_args()


def parse_config(args):
    config = dict()

    with open(args.settings_file) as f:
        exec f in dict(), config

    return config


def main():
    args = parse_args()
    config = parse_config(args)

    # Log to stdout, caller collects all output anyway.
    logging.basicConfig(
            datefmt="%Y-%m-%d %H:%M:%S",
            format="%(asctime)s " + args.region + " %(levelname)s %(message)s",
            level=logging.INFO,
            stream=sys.stdout)

    # Create client for the current region.
    ec2 = boto3.client('ec2', region_name=args.region)

    # Create root snapshot by copying from source region.
    source_region = config["REGION"]
    source_snapshot_id = args.snapshot_id

    dest_region = args.region
    dest_snapshot_id = args.snapshot_id

    if source_region != dest_region:
        r = boto3_check(
                ec2.copy_snapshot,
                SourceRegion=source_region,
                SourceSnapshotId=source_snapshot_id)
        dest_snapshot_id = r["SnapshotId"]

    # Tag the snapshot.
    r = boto3_check(
            ec2.create_tags,
            Resources=[dest_snapshot_id],
            Tags=[{"Key": "Name", "Value": config["AMI_CHILD_DESCRIPTION"]}])

    # Share the new snapshot with the designated account ids.
    r = boto3_check(
            ec2.modify_snapshot_attribute,
            SnapshotId=dest_snapshot_id,
            CreateVolumePermission={
                "Add": [{"UserId": u} for u in config["AMI_CHILD_USERIDS"]]
            })

    # Wait for the snapshot to complete.
    with logtime("copying snapshot %s" % source_snapshot_id):
        while True:
            r = boto3_check(
                    ec2.describe_snapshots,
                    SnapshotIds=[dest_snapshot_id])
            snapshot = r["Snapshots"][0]
            state = snapshot["State"]
            logging.info(
                    "snaphot %s: %s %s %s",
                    dest_snapshot_id,
                    state,
                    snapshot.get("Progress", "?"),
                    snapshot.get("StateMessage", "<no message>"))
            if state == "completed":
                break
            assert state == "pending"
            time.sleep(20)

    # Register the new image.
    # It's only difference from the source image is the root snapshot id.
    source_ami = json.loads(args.parent_ami_json)

    register_args = dict()
    register_args["Name"] = config["AMI_CHILD_NAME"]
    register_args["Description"] = config["AMI_CHILD_DESCRIPTION"]

    for k in "Architecture RootDeviceName VirtualizationType".split():
        register_args[k] = source_ami[k]

    for k in "KernelId RamdiskId SriovNetSupport".split():
        if k in source_ami:
            register_args[k] = source_ami[k]

    register_args["BlockDeviceMappings"] = copy.copy(source_ami["BlockDeviceMappings"])
    for mapping in register_args["BlockDeviceMappings"]:
        if mapping["DeviceName"] == register_args["RootDeviceName"]:
            ebs = mapping["Ebs"]
            ebs["SnapshotId"] = dest_snapshot_id
            if "Encrypted" in ebs:
                del ebs["Encrypted"]

    r = boto3_check(
            ec2.register_image,
            **register_args)
    dest_image_id = r["ImageId"]

    # Share the new image with the designated account ids.
    r = boto3_check(
            ec2.modify_image_attribute,
            ImageId=dest_image_id,
            LaunchPermission={
                "Add": [{"UserId": u} for u in config["AMI_CHILD_USERIDS"]]
            })

    results = {
        "region": dest_region,
        "image_id": dest_image_id
    }

    with open(args.output_path, "w") as f:
        f.write(json.dumps(results) + "\n")


if __name__ == "__main__":
    with logtime(sys.argv[0]):
        main()
