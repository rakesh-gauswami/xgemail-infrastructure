#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Download, decrypt, and install cookbooks.
"""

# TODO: We should use KMS server-side encryption for cookbooks instead
# of explicitly encrypting and decrypting with the openssl command.

import boto3
import optparse
import os
import subprocess
import time


# Default directory where cookbooks are to be installed.
DEFAULT_CHEF_REPO_DIR = "/var/chef/chef-repo"


# Default S3 bucket from which cookbooks are downloaded.
# The default is set to cloud-applications because that is the bucket
# used by the old AMI build plans that run in the hmr-core account.
# Once we have completed the transition to using the AMI Bakery for
# all AMI builds we may change the default to something else.
DEFAULT_BUCKET = "cloud-applications"


def parse_command_line():
    parser = optparse.OptionParser()

    parser.add_option(
            "-c", "--chefdir", default=DEFAULT_CHEF_REPO_DIR,
            help="Chef repo directory")

    parser.add_option(
            "-r", "--region", metavar="REGION", default=None,
            help="AWS region containing bucket")

    parser.add_option(
            "-b", "--bucket", default=DEFAULT_BUCKET,
            help="S3 bucket containing cookbooks")

    parser.add_option(
            "-f", "--folder", default=None,
            help="S3 virtual folder within bucket containing cookbooks")

    parser.add_option(
            "-p", "--password", default=None,
            help="Decryption password for cookbooks")

    options, args = parser.parse_args()

    if len(args) > 0:
        parser.error("too many arguments")

    if options.folder is None:
        parser.error("missing required folder option")

    if options.password is None:
        parser.error("missing required password option")

    return options


def write_file(path, content, chmod=None):
    with open(path, "w") as fp:
        fp.write(content)

    if chmod is not None:
        subprocess.check_call(["chmod", chmod, path])


def s3_get_bytes(region, bucket, key):
    if region is None:
        # Temporarily use us-west-2 to find the bucket region.
        s3_client = boto3.client("s3", region_name="us-west-2")
        response = s3_client.get_bucket_location(Bucket=bucket)
        region = response["LocationConstraint"]

    # Now use an S3 client for the correct region.
    s3_client = boto3.client("s3", region_name=region)
    response = s3_client.get_object(Bucket=bucket, Key=key)
    return response["Body"].read()


def decrypt_file(source, dest, password):
    command = [
        "openssl",
        "enc",
        "-aes-256-cbc",
        "-d",
        "-in", source,
        "-out", dest,
        "-pass", "pass:%s" % password
    ]
    subprocess.check_call(command)


def _main():
    options = parse_command_line()

    # Work in the chef-repo directory.
    os.chdir(options.chefdir)

    # These paths are relative to the chef-repo path.
    cookbook_paths = ["cookbooks", "berks-cookbooks"]
    node_paths = ["nodes"]

    # Incorporate the chef-repo path.
    cookbook_paths = map(lambda s: os.path.join(options.chefdir, s), cookbook_paths)
    node_paths = map(lambda s: os.path.join(options.chefdir, s), node_paths)

    # Use the same configuration for chef and knife.
    configuration = "cookbook_path %s\nnode_path %s\n" % (
            repr(cookbook_paths),
            repr(node_paths))

    subprocess.check_call(["mkdir", "-p", ".chef"])
    write_file(".chef/client.rb", configuration, chmod="0644")
    write_file(".chef/knife.rb",  configuration, chmod="0644")

    # Backup the old cookbooks.
    backup_directory = time.strftime("cookbooks.backup.%Y%m%d.%H%M%S")
    if os.path.exists("cookbooks"):
        subprocess.check_call(["mkdir", "-p", backup_directory])
        subprocess.check_call(["mv", "cookbooks", backup_directory])
    if os.path.exists("cookbooks.enc"):
        subprocess.check_call(["mkdir", "-p", backup_directory])
        subprocess.check_call(["mv", "cookbooks.enc", backup_directory])

    # Download the encrypted cookbooks.
    cookbooks_enc_bytes = s3_get_bytes(options.region, options.bucket, options.folder + "/cookbooks.enc")
    write_file("cookbooks.enc", cookbooks_enc_bytes)

    # Decrypt and unpack.
    decrypt_file("cookbooks.enc", "cookbooks.tar.gz", options.password)
    subprocess.check_call(["tar", "xvf", "cookbooks.tar.gz"])


if __name__ == "__main__":
    _main()
