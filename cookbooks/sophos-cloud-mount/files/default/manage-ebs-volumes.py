#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2021, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# manage-ebs-volumes.py: backup, install, or update EBS volumes.

# TODO ;;; Remove mongo-specificity by having caller compute total size, volume key, etc?

# TODO ;;; Implement backup code.

# TODO ;;; Implement restore code.

# TODO ;;; Implement update code.


import boto3
import json
import logging
import optparse
import os
import pprint
import subprocess
import sys
import time
import traceback


def info(s):
    logging.info(s)
    print s


def metadata(path):
    url = "http://169.254.169.254/latest/meta-data/%s" % path
    cmd = "wget --quiet --timeout=5 --tries=1 -O- %s" % url
    argv = cmd.split()
    return subprocess.check_output(argv)


def parse_command_line():
    parser = optparse.OptionParser(
            usage="%prog [options] backup|restore|install|update")

    # These options are all useful for development and testing.

    parser.add_option(
            "-f", "--fresh", action="store_true", default=False,
            help="force fresh volume set")

    parser.add_option(
            "-n", "--nomount", action="store_true", default=False,
            help="disable preparation of volumes and mounting of file systems")

    parser.add_option(
            "-d", "--debug", action="store_true", default=False,
            help="log more")

    parser.add_option(
            "-v", "--verbose", action="store_true", default=False,
            help="print more")

    options, args = parser.parse_args()

    if len(args) < 1:
        parser.error("missing required action argument")

    if len(args) > 1:
        parser.error("too many arguments")

    actions = ["backup", "restore", "install", "update"]
    action = args[0]
    if action not in actions:
        parser.error("invalid action '%s'" % action)

    return options, action


class AWSWrapper(object):
    def __init__(self, region):
        self._print_responses = False

        self._ec2_client = boto3.client("ec2", region_name=region)
        self._ec2_resource = boto3.resource("ec2", region_name=region)

        self._kms_client = boto3.client("kms", region_name=region)

        self._sdb_client = boto3.client("sdb", region_name=sdb_region)

    def set_logging_level(self, level):
        logging.getLogger("boto3").setLevel(level)
        logging.getLogger("botocore").setLevel(level)

    def set_print_responses(self, print_responses):
        self._print_responses = print_responses

    def ec2_attach_volume(self, volume_id, instance_id, device):
        return self._check_response(
            self._ec2_client.attach_volume(
                VolumeId    = volume_id,
                InstanceId  = instance_id,
                Device      = device),
            "ec2.attach_volume()")

    def ec2_create_tags(self, resource_id, tags):
        return self._check_response(
            self._ec2_client.create_tags(Resources=[resource_id], Tags=tags),
            "ec2.create_tags()")

    def ec2_create_volume(self, availability_zone, kms_arn, size_gb, iops):
        if iops > 0:
            return self._check_response(
                self._ec2_client.create_volume(
                    AvailabilityZone    = availability_zone,
                    Encrypted           = True,
                    KmsKeyId            = kms_arn,
                    VolumeType          = "io1",
                    Size                = size_gb,
                    Iops                = iops),
                "ec2.create_volume()")
        else:
            return self._check_response(
                self._ec2_client.create_volume(
                    AvailabilityZone    = availability_zone,
                    Encrypted           = True,
                    KmsKeyId            = kms_arn,
                    VolumeType          = "gp3",
                    Size                = size_gb),
                "ec2.create_volume()")

    def ec2_describe_volume(self, volume_id):
        return self._check_response(
            self._ec2_client.describe_volumes(VolumeIds = [volume_id]),
            "ec2.describe_volume()")

    def ec2_volume(self, volume_id):
        return self._ec2_resource.Volume(volume_id)

    def kms_list_aliases(self):
        return self._kms_client.get_paginator('list_aliases').paginate().build_full_result()

    def sdb_get_attributes(self, domain, item):
        return self._check_response(
                self._sdb_client.get_attributes(
                    DomainName      = domain,
                    ItemName        = item,
                    ConsistentRead  = True),
                "sdb.get_attributes()")

    def sdb_put_attributes(self, domain, item, attributes):
        return self._check_response(
                self._sdb_client.put_attributes(
                    DomainName = domain,
                    ItemName   = item,
                    Attributes = attributes),
                "sdb.put_attributes()")

    def _check_response(self, response, request_description):
        if self._print_responses:
            print "response from %s:" % request_description
            pprint.pprint(response, indent=4)

        assert response is not None, "%s returned None" % request_description

        status = response["ResponseMetadata"]["HTTPStatusCode"]
        assert status == 200, "%s returned HTTPStatusCode %s" % (
                request_description, status)

        return response


class InstanceSettings(object):
    def __init__(self):
        # sophos_cloud attributes
        self.application_type   = None
        self.availability_zone  = None
        self.environment        = None
        self.region             = None
        self.sdb_region         = None
        self.vpc_name           = None

        # volumes attributes
        self.volume_min_iops             = None
        self.volume_min_size_data_gb     = None
        self.volume_count               = None
        self.volume_iops                = None
        self.volume_size_gb             = None
        self.volume_set_id              = None
        self.volume_mount_point         = None
        self.volume_tracker_sdb_domain  = None

        # derived attributes
        self.kms_alias                  = None
        self.volume_key                 = None
        self.volume_tracker_sdb_item    = None

    def load(self, path):
        with open(path) as fp:
            self.loadfp(fp)

    def loadfp(self, fp):
        attributes = json.load(fp)

        sophos_attrs = attributes["sophos_cloud"]
        self.application_type           = sophos_attrs["application_type"]
        self.availability_zone          = sophos_attrs["availability_zone"]
        self.environment                = sophos_attrs["environment"]
        self.region                     = sophos_attrs["region"]
        self.sdb_region                 = sophos_attrs["sdb_region"]
        self.vpc_name                   = sophos_attrs["vpc_name"]

        volume_attrs = attributes["volumes"]
        self.volume_min_iops            = int(volume_attrs["volume_min_iops"])
        self.volume_min_size_data_gb    = int(volume_attrs["volume_min_size_data_gb"])
        self.volume_count               = 1
        self.volume_iops                = self.volume_min_iops
        self.volume_size_gb             = self.volume_min_size_data_gb
        self.volume_set_id              = volume_attrs["volume_set_id"]
        self.volume_mount_point         = os.path.normpath("/" + volume_attrs["volume_mount_point"])
        self.volume_tracker_sdb_domain  = volume_attrs["volume_tracker_sdb_domain"]

        # Example: alias/cloud-inf-mongodata
        self.kms_alias = "alias/cloud-%s-%s" % (
            self.environment,
            os.path.relpath(self.volume_mount_point, "/"))
        if 'kms_alias' in volume_attrs:
            self.kms_alias = volume_attrs['kms_alias']

        # Example: CloudStation:mongodb:us-west-2a
        self.volume_key = "%s:%s:%s:%s" % (
                self.vpc_name,
                self.application_type,
                self.availability_zone,
                self.volume_set_id)

        # Example: CloudStation:mongodb:upe_f87a:us-west-2a:provisional
        self.volume_tracker_sdb_item = "%s:%s" % (self.volume_key, self.volume_set_id)


class VolumeSet(object):
    def __init__(self, volumes):
        self._volumes = { volume.volume_id: volume for volume in volumes }

    def volume_ids(self):
        return [ volume_id for volume_id in sorted(self._volumes.keys()) ]

    def volume(self, volume_id):
        return self._volumes[volume_id]


class App(object):
    def __init__(self, options):
        self.options = options

        self.settings = InstanceSettings()
        self.settings.load("/var/sophos/cookbooks/attributes.json")

        self.aws_wrapper = AWSWrapper(self.settings.region)
        self.aws_wrapper.set_logging_level(logging.DEBUG if options.debug else logging.ERROR)
        self.aws_wrapper.set_print_responses(options.verbose)

        self.instance_id = metadata("instance-id")

        # We're going to go ahead and create a logical volume now, even if
        # we only have a single volume, so when we add support for multiple
        # volumes we can extend existing volume sets more easily.

        basename = os.path.basename(self.settings.volume_mount_point)
        self.volume_group = basename + "_vg"
        self.logical_volume = basename + "_lv"
        self.logical_volume_device = "/dev/%s/%s" % (self.volume_group, self.logical_volume)

        info("kms_alias:             %s" % self.settings.kms_alias)
        info("instance_id:           %s" % self.instance_id)
        info("volume_key:            %s" % self.settings.volume_key)
        info("volume_count:          %s" % self.settings.volume_count)
        info("volume_iops:           %s" % self.settings.volume_iops)
        info("volume_size_gb:        %s" % self.settings.volume_size_gb)
        info("volume_set_id:         %s" % self.settings.volume_set_id)
        info("volume_mount_point:    %s" % self.settings.volume_mount_point)
        info("volume_group:          %s" % self.volume_group)
        info("logical_volume:        %s" % self.logical_volume)
        info("logical_volume_device: %s" % self.logical_volume_device)

    def _run(self, argv):
        info("running: %s" % argv)

        pipe = subprocess.Popen(
                argv,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                close_fds=True,
                universal_newlines=True)

        out, err = pipe.communicate()

        for line in out.splitlines():
            info("out: " + line)

        for line in err.splitlines():
            info("err: " + line)

        info("ret: %d" % pipe.returncode)

        if pipe.returncode > 0:
            raise Exception("failed, command '%s' exited with status %d" % (
                argv, pipe.returncode))

        if pipe.returncode < 0:
            raise Exception("failed, command '%s' terminated by signal %d" % (
                argv, -pipe.returncode))

        return out

    def backup(self):
        # TODO ;;; Implement

        # Take a synchronized EBS snapshot of the underlying volumes.
        # We must assume the the caller made sure that mongod was stopped.

        pass

    def restore(self):
        # TODO ;;; Implement

        # Restore by creating a new volume set from a given snapshot set.
        # We must assume the the caller made sure that mongod was stopped.
        # We must also make sure that if this code is called multiple times
        # with the same snapshot id, we don't accidentally overwrite the
        # restored and updated volumes.
        # We may need to require a new volume set id for this.

        pass

    def install(self):
        # Find or create the volumes we want to attach.
        volume_set = self._fetch_volume_set()
        if volume_set is None or self.options.fresh:
            volume_set = self._create_volume_set_or_die()

        # Make sure the volumes exist, aren't attached to another instance, etc.
        self._check_volume_set_or_die(volume_set)

        # Attach the volumes to the current instance.
        self._attach_volume_set_or_die(volume_set)

        if self.options.nomount:
            return

        # Prepare the volumes.  Determine if we need to create a logic volume
        # or not by running the pvs command to list physical volumes.
        pvs_output = self._run(["/sbin/pvs", "--noheadings"]).strip()
        if pvs_output == "":
            # If there is no output then we never created any physical volumes.
            # Of course, this assumes we never created any physical volumes for
            # any OTHER purpose, but that seems like a safe assumption for now.
            self._create_logical_volume_or_die(volume_set)
            self._create_file_system_or_die()
        else:
            # If there are physical volumes then there should be a logical
            # volume and a file system we can mount.  That's because we can
            # only get here by successfully attaching to existing volumes
            # recorded in a volume set in SimpleDB, and we only record volume
            # sets in SimpleDB after we have successully created the logical
            # volume and mounted the file system.
            self._activate_logical_volume_or_die()
        self.check_logical_volume_or_die()

        # Mount a filesystem over the volumes.
        self.mount_file_system_or_die()
        self.check_file_system_or_die(volume_set)

        # We defer storing the volume set and tagging the volumes until after
        # the volumes have been attached and mounted to avoid leaving a false
        # impression in the AWS console that the volumes we couldn't attach
        # or mount are actually being used by this instance.
        #
        # Besides, if the problem was that the volumes are being used by
        # another instance, premature storage and tagging would only compound
        # the problem.
        #
        # But, now that everything has succeeded ...

        # Make sure we can find the volumes after this instance is terminated.
        self._store_volume_set_or_die(volume_set)

        # Tag the volumes so we can find them in the AWS console.
        self._tag_volume_set_or_die(volume_set)

    def update(self):
        # TODO ;;; Implement

        # Possible updates:
        #
        #   1) The volume set id changed:
        #       Unmount current volume set.
        #       Detach current volume set.
        #       Call install method to create, check, attach, and mount new volume set.
        #       NOTE: this does NOT transfer any data between old volumes and new;
        #           We COULD re-mount the old volume set at a different mount point and
        #           explicitly copy files from old volume set to new if we want.
        #           This may take a while because of the need to warm the new volumes.
        #           We COULD address that by creating and maybe pre-warming the volumes
        #           before stopping the server and unmounting the old volumes...
        #
        #   2) The desired total size changed.
        #       Unmount the current volume set (is this necessary?)
        #       Create and check additional volumes.
        #       Extend the logical volume to include the new volumes.
        #       Remount the extended logical volume.
        #       Expand the file system.
        #       Don't forget to update the volume set in SimpleDB and re-tag the volumes.

        pass

    def _fetch_volume_set(self):
        response = self.aws_wrapper.sdb_get_attributes(
                self.settings.volume_tracker_sdb_domain,
                self.settings.volume_tracker_sdb_item)

        d = dict()
        attributes = response.get("Attributes")
        if attributes is not None:
            for attribute in attributes:
                k = attribute["Name"]
                v = attribute["Value"]
                d[k] = v

        if len(d) == 0:
            return None

        volume_key = d.get("volume_key")
        if volume_key is None:
            return None

        volume_set_id = d.get("volume_set_id")
        if volume_set_id is None:
            return None

        volume_ids = d.get("volume_ids", "").split()
        if len(volume_ids) == 0:
            return None

        volumes = []
        for volume_id in volume_ids:
            volume = self.aws_wrapper.ec2_volume(volume_id)
            volumes.append(volume)

        return VolumeSet(volumes)

    def _store_volume_set_or_die(self, volume_set):
        # Store the volume data in SimpleDB.
        self.aws_wrapper.sdb_put_attributes(
                self.settings.volume_tracker_sdb_domain,
                self.settings.volume_tracker_sdb_item,
                [{
                    "Name": "volume_key",
                    "Value": self.settings.volume_key,
                    "Replace": True
                }, {
                    "Name": "volume_set_id",
                    "Value": self.settings.volume_set_id,
                    "Replace": True
                }, {
                    "Name": "volume_ids",
                    "Value": " ".join([volume_id for volume_id in volume_set.volume_ids()]),
                    "Replace": True
                }])

    def _tag_volume_set_or_die(self, volume_set):
        for volume_id in volume_set.volume_ids():
            self.aws_wrapper.ec2_create_tags(
                    volume_id,
                    [{
                        "Key": "Name",
                        "Value": self.settings.volume_key
                    }, {
                        "Key": "VolumeSetId",
                        "Value": self.settings.volume_set_id
                    }])

    def _create_volume_set_or_die(self):
        kms_arn = self._get_kms_arn()

        volumes = []
        for _ in range(self.settings.volume_count):
            volume = self._create_volume(kms_arn)
            volumes.append(volume)

        # Wait for volumes to become available.

        available = [False for _ in volumes]
        while not all(available):
            # We have to sleep a little to avoid exceeding API call rate limit.
            time.sleep(1)

            for i, volume in enumerate(volumes):
                if available[i]:
                    continue

                volume_id = volume.volume_id

                response = self.aws_wrapper.ec2_describe_volume(volume_id)

                state = response["Volumes"][0]["State"]

                if state == "creating":
                    continue

                if state == "available":
                    available[i] = True
                    continue

                # Other states are errors for us: in-use, deleting, deleted, error
                raise Exception("failed, volume '%s' state '%s'" % (volume_id, state))

        return VolumeSet(volumes)

    def _get_kms_arn(self):
        response = self.aws_wrapper.kms_list_aliases()

        aliases = response["Aliases"]

        for alias in aliases:
            if alias["AliasName"] == self.settings.kms_alias:
                # Want to return arn:aws:kms:<region>:<accountid>:key/<keyid>
                # Start with arn:aws:kms:<region>:<accountid> from the alias ARN.
                arn_components = alias["AliasArn"].split(":")[0:5]

                # Add the key.
                arn_components.append("key/%s" % alias["TargetKeyId"])

                # Return the string.
                return ":".join(arn_components)

        assert False, "cannot find ARN for KMS alias %s" % self.settings.kms_alias

    def _create_volume(self, kms_arn):
        response = self.aws_wrapper.ec2_create_volume(
                self.settings.availability_zone,
                kms_arn,
                self.settings.volume_size_gb,
                self.settings.volume_iops)

        info("created volume: %s size: %s iops: %s encrypted: %s state: %s" % (
            response["VolumeId"],
            response["Size"],
            response["Iops"],
            response["Encrypted"],
            response["State"]))

        volume = self.aws_wrapper.ec2_volume(response["VolumeId"])

        return volume

    def _check_volume_set_or_die(self, volume_set):
        for volume_id in volume_set.volume_ids():
            volume = volume_set.volume(volume_id)

            # If the volume is attached to any instance it must THIS instance.
            for attachment in volume.attachments:
                attached_instance_id = attachment.get("InstanceId")
                if attached_instance_id is not None:
                    assert attached_instance_id == self.instance_id, \
                            "volume '%s' is attached to other instance '%s'" % (
                                    volume_id, attached_instance_id)

            # The volume must be in the correct AZ.
            assert volume.availability_zone == self.settings.availability_zone, \
                "volume '%s' should be in availability zone '%s'" % (
                        volume_id, self.settings.availability_zone)

            # The volume must be encrypted.
            assert volume.encrypted, \
                "volume '%s' should be encrypted" % volume_id

    def _attach_volume_set_or_die(self, volume_set):
        # Get list of devices we can attach volumes to.

        existing_devices = set(["/dev/%s" % d for d in os.listdir("/dev")])
        possible_devices = []
        for c in "fghijklmnopqrstuvwxyz":
            device = "/dev/xvd%s" % c
            if device not in existing_devices:
                possible_devices.append(device)

        # Start the attachment process for each volume.
        # Skip volumes that are already attached to this instance.

        volume_ids = volume_set.volume_ids()
        volume_ids_to_attach = []

        for i, volume_id in enumerate(volume_ids):
            attached_to_this_instance = False
            response = self.aws_wrapper.ec2_describe_volume(volume_id)
            for attachment in response["Volumes"][0]["Attachments"]:
                if attachment["InstanceId"] == self.instance_id:
                    if attachment["State"] in ["attaching", "attached"]:
                        attached_to_this_instance = True
                        break

            if attached_to_this_instance:
                continue

            volume_ids_to_attach.append(volume_id)

            device = possible_devices[i]
            self.aws_wrapper.ec2_attach_volume(
                    volume_id, self.instance_id, device)

        # Wait for attachments to complete.

        attached = [False for _ in volume_ids_to_attach]
        while not all(attached):
            # We have to sleep a little to avoid exceeding API call rate limit.
            time.sleep(1)

            for i, volume_id in enumerate(volume_ids_to_attach):
                if attached[i]:
                    continue

                device = possible_devices[i]

                response = self.aws_wrapper.ec2_describe_volume(volume_id)

                state = None
                for attachment in response["Volumes"][0]["Attachments"]:
                    if attachment["Device"] == device:
                        state = attachment["State"]
                        break

                if state == "attaching":
                    continue

                if state == "attached":
                    attached[i] = True
                    continue

                # Other states are errors for us: detaching, detached, None
                raise Exception("failed, volume '%s' device '%s' state '%s'" % (volume_id, device, state))

    def _create_logical_volume_or_die(self, volume_set):
        # We need a map from volume_id to device path.
        devices = self._get_devices_dict(volume_set)

        # First create the physical volumes.
        physical_volumes = []
        for volume_id in volume_set.volume_ids():
            device = devices[volume_id]
            self._run(["/sbin/pvcreate", "-y", device])
            physical_volumes.append(device)

        # Next, create a volume group from the all the physical volumes.
        self._run(["/sbin/vgcreate", self.volume_group] + physical_volumes)

        # Finally, create a logical volume from the volume group.
        # We don't use striping; for greater throughput provision more IOPS.
        # Otherwise we have to add volumes in multiples of the stripe count.
        # We don't set readahead.  The MongoDB Production Notes only mention
        # setting it for the MMapV1 storage engine, not for Wired Tiger.
        self._run([
            "/sbin/lvcreate",
            "--name", self.logical_volume,
            "--extents", "100%VG",
            self.volume_group])

    def _get_devices_dict(self, volume_set):
        devices = dict()

        volume_ids = volume_set.volume_ids()
        for volume_id in volume_ids:
            volume = volume_set.volume(volume_id)

            device = None
            response = self.aws_wrapper.ec2_describe_volume(volume_id)
            for attachment in response["Volumes"][0]["Attachments"]:
                if attachment["VolumeId"] != volume_id:
                    continue
                if attachment["InstanceId"] != self.instance_id:
                    continue
                if attachment["State"] != "attached":
                    continue
                device = attachment["Device"]
                break

            if device is None:
                raise Exception("failed, no attachment from instance '%s' to volume '%s'" % (
                    self.instance_id, volume_id))

            devices[volume_id] = device

        return devices

    def _create_file_system_or_die(self):
        # Always use XFS.  Never use the -f option to force an overwrite.
        self._run(["/sbin/mkfs.xfs", self.logical_volume_device])

    def _activate_logical_volume_or_die(self):
        self._run(["/sbin/vgchange", "--activate", "y"])

    def check_logical_volume_or_die(self):
        lvs_output = self._run(["/sbin/lvs", "--noheadings", "-o", "lv_path,lv_kernel_major"])
        path, active = lvs_output.strip().split(None, 1)
        assert path == self.logical_volume_device, \
                "failed, lv_path is '%s', expected '%s'" % (path, self.logical_volume_device)
        assert active != -1, \
                "failed, lv_kernel_major is '%s', volume not active" % active

    def mount_file_system_or_die(self):
        # Make sure the mount point exists.
        assert os.path.isdir(self.settings.volume_mount_point), \
                "failed, mount point '%s' not a directory" % self.settings.volume_mount_point

        # Record the mount information in /etc/fstab, then run the mount command.
        # Some online documentation has you run mount and then edit /etc/fstab,
        # but that way is dangerous, you might end up with different mount options
        # in /etc/fstab and mount the filesystem differently after rebooting the
        # instance.
        with open("/etc/fstab", "a") as fp:
            print >>fp, "%s %s xfs defaults,noexec,nosuid 0 0" % (
                    self.logical_volume_device,
                    self.settings.volume_mount_point)
        self._run(["/bin/mount", self.logical_volume_device])

    def check_file_system_or_die(self, volume_set):
        # Store the volume data on the volume itself.
        volume_info = {
            "volume_set_id": self.settings.volume_set_id,
            "volume_key": self.settings.volume_key,
            "volume_ids": volume_set.volume_ids()
        }
        path = "%s/volume_info.json" % self.settings.volume_mount_point
        with open(path, "w") as fp:
            json.dump(volume_info, fp, indent=4, sort_keys=True)
            fp.write("\n")
        os.chmod(path, 0644)

        # Make sure we can read back what we wrote.
        with open(path, "r") as fp:
            reloaded_volume_info = json.load(fp)
            reloaded_items = sorted(reloaded_volume_info.items())
            original_items = sorted(volume_info.items())
            assert original_items == reloaded_items, \
                    "failed, read/write test failed for '%s'" % path


def main():
    options, action = parse_command_line()

    try:
        logging.basicConfig(
                format="%(asctime)s %(process)d %(levelname)s %(name)s %(message)s",
                filename="/var/log/manage-ebs-volumes.log",
                level=logging.DEBUG)

        logging.info("launched: sys.argv: %s" % sys.argv)

        app = App(options)

        if action == 'backup':
            app.backup()
        elif action == 'restore':
            app.restore()
        elif action == 'install':
            app.install()
        elif action == 'update':
            app.update()
        else:
            assert False, "NOTREACHED"

    except SystemExit as e:
        info("exit code: %s" % e.code)
        raise

    except Exception as e:
        trace = traceback.format_exc()
        for line in trace.splitlines():
            info(line)
        raise


if __name__ == "__main__":
    main()
