#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
Find or create CloudFront origin access identity.
Existing identities are identified by the comment assigned to them.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import time


def parse_command_line():
    import optparse

    parser = optparse.OptionParser(
            usage="%prog REGION COMMENT")

    options, args = parser.parse_args()

    if len(args) < 2:
        parser.error("too few arguments")

    region, comment = args

    return region, comment


def print_origin_access_identity(item):
    print "OriginAccessId=%s" % item["Id"]
    print "OriginAccessCanonicalUser=%s" % item["S3CanonicalUserId"]


def find_or_create_origin_access_identity(region, comment):
    import boto3

    client = boto3.client("cloudfront", region_name=region)

    response = client.list_cloud_front_origin_access_identities()
    items = response["CloudFrontOriginAccessIdentityList"].get("Items", [])

    for item in items:
        if item.get("Comment") == comment:
            print_origin_access_identity(item)
            return

    response = client.create_cloud_front_origin_access_identity(
            CloudFrontOriginAccessIdentityConfig={
                "CallerReference": str(int(time.time()*1000)),
                "Comment": comment
            })
    item = response["CloudFrontOriginAccessIdentity"]
    print_origin_access_identity(item)

def main():
    region, comment = parse_command_line()
    find_or_create_origin_access_identity(region, comment)


if __name__ == "__main__":
    main()
