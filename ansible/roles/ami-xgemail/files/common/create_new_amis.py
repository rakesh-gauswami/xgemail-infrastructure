#!/usr/bin/env python
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# common/create_new_amis.py: create new root volume and register images

import argparse
import boto3
import json
import logging
import os
import pprint
import shutil
import sys
import time

from sophos_common import *


def parse_args():
    parser = argparse.ArgumentParser(
            usage="%(prog)s [-h] settings_file configure_command...")

    parser.add_argument(
            "settings_file",
            help="python file containg configuration setting assignments")

    parser.add_argument(
            "configure_dir",
            help="directory to create on target and run configure command from")

    parser.add_argument(
            "configure_command", nargs='+',
            help="command run inside chroot to configure the new root volume")

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
            format="%(asctime)s " + config["REGION"] + " %(levelname)s %(message)s",
            level=logging.INFO,
            stream=sys.stdout)

    # Create EC2 client for the current region.
    ec2 = boto3.client('ec2', region_name=config["REGION"])

    # Create S3 client for us-west-2, always.
    s3 = boto3.client('s3', region_name="us-west-2")

    # Find the parent AMI.
    r = boto3_check(
            ec2.describe_images,
            Filters=[{"Name": "image-id", "Values": [config["AMI_PARENT_ID"]]}])
    ami = r["Images"][0]

    # Find the parent root volume description.
    parent_root_ebs = None
    for mapping in ami["BlockDeviceMappings"]:
        if mapping["DeviceName"] == ami["RootDeviceName"]:
            parent_root_ebs = mapping["Ebs"]
    assert parent_root_ebs is not None

    # Create a new volume from the parent root volume snapshot.
    availability_zone = aws_availability_zone()
    r = boto3_check(
            ec2.create_volume,
            AvailabilityZone=availability_zone,
            SnapshotId=parent_root_ebs["SnapshotId"])
    volume_id = r["VolumeId"]

    # Tag the volume.
    r = boto3_check(
            ec2.create_tags,
            Resources=[volume_id],
            Tags=[{"Key": "Name", "Value": config["AMI_CHILD_DESCRIPTION"]}])

    # Wait for the volume to become available.
    with logtime("creating volume %s" % volume_id):
        while True:
            r = boto3_check(
                    ec2.describe_volumes,
                    VolumeIds=[volume_id])
            state = r["Volumes"][0]["State"]
            logging.info("volume %s: %s", volume_id, state)
            if state == "available":
                break
            assert state == "creating"
            time.sleep(5)

    # Attach the new volume.
    device = next_available_device()
    instance_id = aws_instance_id()
    r = boto3_check(
            ec2.attach_volume,
            Device=device,
            InstanceId=instance_id,
            VolumeId=volume_id)
    disk_device = r["Device"]

    # Wait for the volume to attach.
    with logtime("attaching volume %s" % volume_id):
        while True:
            r = boto3_check(
                    ec2.describe_volumes,
                    VolumeIds=[volume_id])
            state = r["Volumes"][0]["State"]
            logging.info("volume %s: %s", volume_id, state)
            if state == "in-use":
                break
            assert state == "available"
            time.sleep(5)

    # Find the path to the mountable device partition.
    partition_device = find_partition_device(disk_device)

    # Create the mount point for the new root volume.
    mount_point = "/mnt/ami_root"
    check_call("/bin/mkdir", "-p", mount_point)

    # Mount the newly attached volume.
    check_call("/bin/mount", partition_device, mount_point)

    # Create a directory for the installer code on the new volume.
    install_dir_target_path = "/" + args.configure_dir
    install_dir_host_path = mount_point + "/" + args.configure_dir
    check_call("/bin/mkdir", "-p", install_dir_host_path)

    # Copy installer code onto new volume.
    check_call("/bin/cp", "-r", ".", install_dir_host_path)

    # The target volume may not have /etc/resolv.conf installed,
    # as DHCP has not been set up on it. This break yum and anything
    # that needs to resolve a hostname.
    check_call("/bin/cp", "/etc/resolv.conf", mount_point + "/etc/resolv.conf")

    # Mount the special file systems in the chroot jail.
    check_call("/bin/mount", "-v", "-t", "proc", "none", mount_point + "/proc")
    check_call("/bin/mount", "-v", "-t", "sysfs", "none", mount_point + "/sys")
    check_call("/bin/mount", "-v", "--bind", "/dev", mount_point + "/dev")

    # Run in chroot so absolute paths will be relative to mount point.
    with cd(install_dir_host_path):
        with logtime("chroot command"):
            check_call(
                    "/usr/sbin/chroot",
                    mount_point,
                    *args.configure_command)

    # Copy logs from target volume.
    sophos_logs_host_path = "/var/log/sophos"
    sophos_logs_target_path = mount_point + sophos_logs_host_path
    copied_from_target_path = "/var/log/sophos/copied-from-target"
    check_call("/bin/mkdir", "-p", sophos_logs_target_path)
    for leaf in os.listdir(sophos_logs_target_path):
        source_path = os.path.join(sophos_logs_target_path, leaf)
        try:
            check_call("/bin/mkdir", "-p", copied_from_target_path)
            check_call("/bin/cp", "-r", source_path, copied_from_target_path)
        except Exception as e:
            # Failure to collect logs is notable but not fatal.
            logging.info("error collecting %s from target volume: %s" % (source_path, str(e)))

    # Log the date and description of the new volume on it.
    with open(mount_point + "/etc/ami-lineage.log", "a") as f:
        f.write("%s %s\n" % (
            check_output("/bin/date", "+%F %T %Z").strip(),
            config["AMI_CHILD_DESCRIPTION"]))

    # Unmount the special file systems.
    check_call("/bin/umount", "-v", mount_point + "/dev")
    check_call("/bin/umount", "-v", mount_point + "/sys")
    check_call("/bin/umount", "-v", mount_point + "/proc")

    # Remove /etc/resolv.conf from the target, now that we are done with it.
    check_call("/bin/rm", "-f", mount_point + "/etc/resolv.conf")

    # Clean up the new volume.
    check_call("/bin/rm", "-rf", install_dir_host_path)
    check_call("/bin/rm", "-rf", mount_point + "/tmp/*")

    # Make REALLY sure writes to the new volume have all been flushed to disk.
    check_call("sync")
    check_call("sync")

    # Once in a GREAT while (saw this only once in maybe 50 builds) the
    # mount point will still be busy immediately after the sync commands
    # return.  So wait in a small loop calling lsof to find out if there
    # are any processes using the directory.  No need for timeout code
    # here, the CloudFormation stack already has one.
    while call("/usr/sbin/lsof", "--", mount_point) == 0:
        time.sleep(2)

    # Unmount the new volume.
    check_call("/bin/umount", "--detach-loop", "--verbose", mount_point)

    # Create a snapshot of the new, configured volume.
    r = boto3_check(
            ec2.create_snapshot,
            VolumeId=volume_id)
    snapshot_id = r["SnapshotId"]

    # Tag the snapshot.
    r = boto3_check(
            ec2.create_tags,
            Resources=[snapshot_id],
            Tags=[{"Key": "Name", "Value": config["AMI_CHILD_DESCRIPTION"]}])

    # Wait for the snapshot to complete.
    with logtime("creating snapshot of %s" % volume_id):
        while True:
            r = boto3_check(
                    ec2.describe_snapshots,
                    SnapshotIds=[snapshot_id])
            snapshot = r["Snapshots"][0]
            state = snapshot["State"]
            logging.info(
                    "snaphot %s: %s %s %s",
                    snapshot_id,
                    state,
                    snapshot.get("Progress", "?"),
                    snapshot.get("StateMessage", "<no message>"))
            if state == "completed":
                break
            assert state == "pending"
            time.sleep(5)

    # Detach the new volume, now that we are done with it.
    r = boto3_check(
            ec2.detach_volume,
            VolumeId=volume_id)

    # Wait for the volume to detach.
    with logtime("detaching volume %s" % volume_id):
        while True:
            r = boto3_check(
                    ec2.describe_volumes,
                    VolumeIds=[volume_id])
            state = r["Volumes"][0]["State"]
            if state == "available":
                break
            assert state == "in-use"
            time.sleep(5)

    # Delete the volume, now that we have a snapshot.
    # No need to wait for the volume to delete.
    r = boto3_check(
            ec2.delete_volume,
            VolumeId=volume_id)

    # Create new images in each destination region, in parallel.
    statuses = []
    processes = []
    image_ids = dict()

    with logtime("registering %d new amis" % len(config["AMI_CHILD_REGIONS"])):
        cmd = os.path.dirname(sys.argv[0]) + "/register_new_ami.py"
        ami_json = json.dumps(ami)
        for child_region in config["AMI_CHILD_REGIONS"]:
            output_path = "/tmp/image-" + child_region
            argv = [cmd, args.settings_file, child_region, snapshot_id, ami_json, output_path]
            logf = os.tmpfile()
            proc = subprocess.Popen(argv, stdout=logf, stderr=logf)
            processes.append((proc, logf, output_path))

        for proc, logf, output_path in processes:
            status = proc.wait()
            statuses.append(status)

            print "<" * 72
            logf.seek(0)
            for line in logf.readlines():
                print line.rstrip()
            logf.close()
            print ">" * 72

            logging.info("Subprocess status: %d", status)

            # While it is tempting to write the image ID to S3 here,
            # that would be wrong because we don't want to write to
            # S3 until we know that ALL subprocesses have succeeded.

            if status == 0:
                with open(output_path) as resultf:
                    output = json.loads(resultf.read())
                    image_ids[output["region"]] = output["image_id"]

    pprint.pprint(image_ids, indent=4)

    for status in statuses:
        assert status == 0

    # Write image ids to S3.
    # We give each file a .txt suffix so that when clicking on it
    # in the Bamboo artifacts tab it is displayed in the browser,
    # not downloaded.
    bucket = config["S3_AMI_ID_BUCKET"]
    for build in [config["BUILD"], "latest"]:
        for region, image_id in image_ids.iteritems():
            # Use a text format we can use to inject variables into Bamboo.
            body = "AmiId=%s\nBundleVersion=%s\n" % (image_id, config["BUILD"])
            filename = "%s/image_%s.txt" % (build, region)
            key = config["S3_AMI_ID_FOLDER"] + "/" + filename
            boto3_check(s3.put_object, Body=body, Bucket=bucket, Key=key)

        # Write single-file summary to S3 to use as Bamboo artifact.
        results = {
            "ami_name": config["AMI_CHILD_NAME"],
            "ami_description": config["AMI_CHILD_DESCRIPTION"],
            "branch": config["BRANCH"],
            "build": config["BUILD"],
            "environment": config["ENVIRONMENT"],
            "image_ids": image_ids
        }
        body = json.dumps(results, indent=4, sort_keys=True) + "\n"
        filename = "%s/images.txt" % build
        key = config["S3_AMI_ID_FOLDER"] + "/" + filename
        boto3_check(s3.put_object, Body=body, Bucket=bucket, Key=key)


if __name__ == "__main__":
    with logtime(sys.argv[0]):
        main()
