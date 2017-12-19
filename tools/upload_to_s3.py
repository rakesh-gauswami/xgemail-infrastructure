#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
Upload files to S3.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import os
import sys


def parse_command_line():
    import optparse

    parser = optparse.OptionParser(
            usage="%prog REGION BUCKET FOLDER PATH(s)")

    options, args = parser.parse_args()

    if len(args) < 4:
        parser.error("too few arguments")

    region = args[0]
    bucket = args[1]
    folder = args[2]
    paths  = args[3:]

    return region, bucket, folder, paths


def info(message):
    sys.stderr.write(sys.argv[0])
    sys.stderr.write(": ")
    sys.stderr.write(message)
    sys.stderr.write("\n")


def die(message):
    info(message)
    sys.exit(1)


def get_key(folder, path):
    return os.path.normpath(folder + "/" + path).strip("/")


def upload_files_to_s3(region, bucket, folder, paths):
    import boto3

    s3_client = boto3.client('s3', region_name=region)

    for i, path in enumerate(paths):
        key = get_key(folder, path)

        with open(path) as body:
            response = s3_client.put_object(
                    Body=body,
                    Bucket=bucket,
                    Key=key)

            if i > 0:
                info("--")

            info("uploaded %s to s3://%s/%s" % (path, bucket, key))
            info("ETag: %s" % response.get("ETag"))
            info("VersionId: %s" % response.get("VersionId"))


def main():
    region, bucket, folder, paths = parse_command_line()
    upload_files_to_s3(region, bucket, folder, paths)


if __name__ == "__main__":
    main()
