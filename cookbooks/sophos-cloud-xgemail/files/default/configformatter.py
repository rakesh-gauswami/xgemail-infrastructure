#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This script is responsible for formatting a config object stored in S3

import formatterutils
import struct

CONFIG_MAGIC_NUMBER = b'\0SOPHCONFIG'

# Nonce length is 0 because we are not encrypting data in V1
NONCE_LENGTH = 0


# Read and verify config magic number
def is_config_file(formatted_s3_config_bytes):
    return formatterutils.is_correct_file_format(
        formatted_s3_config_bytes,
        CONFIG_MAGIC_NUMBER
    )


# Accepts a formatted stream downloaded from S3 which has a zipped json config document
# verifies if it is a right type file by magic number and if yes then
# returns unzipped configuration as json
def get_config_binary(formatted_s3_config):

    # verify if it is a config file first
    if not is_config_file(formatted_s3_config[0:11]):
        raise ValueError("Config file format error: invalid config magic bytes!")

    # Because this formatter must handle various config types, we will not verify the schema version here.

    if not formatterutils.is_unencypted_data(formatted_s3_config[19:23]):
        raise ValueError("Config file format error: invalid config nonce length bytes!")

    return formatterutils.get_decompressed_object_bytes(
        formatted_s3_config[23:len(formatted_s3_config)]
    )


