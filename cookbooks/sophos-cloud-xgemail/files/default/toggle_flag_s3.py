# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2021, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Contains methods to set flag and get flag from S3
# enabling the flag means to put a key in S3 with empty string (data)
# disabling the flag means to delete a key in S3.
# the presence of a key in S3 indicates the flag is turned on
# the absence of a key in S3 indicates the flag is turned off

import argparse
from awshandler import AwsHandler

S3_ENCRYPTION_ALGORITHM = 'AES256'

def set_flag(region, bucket_name, flag_path, flag_value):
    awshandler = AwsHandler(region)
    try:
        existing_flag_value = get_flag(region, bucket_name, flag_path)
        if flag_value:
            if existing_flag_value == True:
                print 'Flag [{}] arleady enabled.'.format(flag_path)
            else:
                awshandler.upload_data_in_s3_without_expiration(
                    bucket_name,
                    flag_path,
                    "",
                    S3_ENCRYPTION_ALGORITHM
                )
                print 'Flag [{}] enabled.'.format(flag_path)
        else:
            if existing_flag_value == False:
                print 'Flag [{}] already disabled.'.format(flag_path)
            else:
                awshandler.delete_object_in_s3(
                    bucket_name,
                    flag_path
                )
                print 'Flag [{}] disabled.'.format(flag_path)
    except Exception as ex:
        print 'Exception [{}] while setting flag [{}] to [{}].'.format(ex, flag_path, flag_value)

def get_flag(region, bucket_name, flag_path):
    awshandler = AwsHandler(region)
    try:
        return awshandler.s3_key_exists(bucket_name, flag_path)
    except Exception as ex:
        print 'Exception [{}] while getting flag [{}]'.format(ex, flag_path)
        return False

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(description='Provides a mechanism for toggling flag in S3')

    parser.add_argument('--region',
        metavar='region',
        help='AWS region'
    )

    parser.add_argument('--bucket',
        metavar='bucket_name',
        help='S3 bucket name'
    )

    parser.add_argument('--get',
        metavar='flag_name',
        help='Get the flag value'
    )
    parser.add_argument('--set',
        metavar=('flag_name'),
        help='name of s3 flag to set'
    )

    parser.add_argument('--unset',
        metavar=('flag_name'),
        help='name of the s3 flag to unset'
    )

    args = parser.parse_args()

    region = args.region
    bucket_name = args.bucket

    if args.get:
        print get_flag(region, bucket_name, args.get)
    elif args.set:
        set_flag(region, bucket_name, args.set, True)
    elif args.unset:
        set_flag(region, bucket_name, args.unset, False)
    else:
        parser.print_help()
