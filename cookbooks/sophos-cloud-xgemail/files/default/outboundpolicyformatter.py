#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This script is responsible for formatting policy object that we store in S3 as
# described here: https://wiki.sophos.net/display/NSG/Send+policy+data+over+to+submit+servers+architecture

import json
import formatterutils

# Outbound format configs
OUTBOUND_SCHEMA_VERSION = 20171026
OUTBOUND_MAGIC_NUMBER = b'\0SOPHCONFIG'
OUTBOUND_FILE_EXTENSION = ".CONFIG"

# Nonce length is 0 because we are not encrypting data in V1
NONCE_LENGTH = 0


# Read and verify policy magic number
def is_policy_file(formatted_s3_policy_bytes):
    return formatterutils.is_correct_file_format(
        formatted_s3_policy_bytes,
        OUTBOUND_MAGIC_NUMBER
    )


# Accepts formatted policy stream downloaded from S3 which has zipped policy json
# verifies if it is a right type file by magic number and if yes then
# returns unzipped policy json
def get_policy_binary(formatted_s3_policy):
    # verify if it is a metadata file first
    if not is_policy_file(formatted_s3_policy[0:11]):
        raise ValueError("Policy file format error: invalid policy magic bytes!")

    if not formatterutils.is_correct_version(OUTBOUND_SCHEMA_VERSION, formatted_s3_policy[11:19]):
        raise ValueError("Policy file format error: invalid policy version bytes!")

    if not formatterutils.is_unencypted_data(formatted_s3_policy[19:23]):
        raise ValueError("Policy file format error: invalid policy nonce length bytes!")

    decompressed_bytes = formatterutils.get_decompressed_object_bytes(
        formatted_s3_policy[23:len(formatted_s3_policy)]
    )
    content = json.loads(decompressed_bytes)

    if "schema_version" in content and content["schema_version"] == OUTBOUND_SCHEMA_VERSION:
        return decompressed_bytes
    else:
        # Schema version field is not present in other configs like rate limit, black-list etc.
        return decompressed_bytes
