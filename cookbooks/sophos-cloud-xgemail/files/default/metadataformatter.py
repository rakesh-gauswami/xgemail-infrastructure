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
# This script is responsible for formatting metadata object that we store in S3 as
# described here: https://wiki.sophos.net/display/SophosCloud/S3+Objects+File+Format

import formatterutils

SCHEMA_VERSION = 20170224
METADATA_MAGIC_NUMBER = b'\0SOPHMETA'
METADATA_FILE_EXTENSION = ".METADATA"

# Nonce length is 0 because we are not encrypting data in V1
NONCE_LENGTH = 0

def get_s3_metadata_path(s3_path):
    return formatterutils.get_s3_file_path(
        s3_path,
        METADATA_FILE_EXTENSION
    )

# Binary file format with Big Endian (Network) byte order except encryption
# Magic Bytes:  { '\0', 'S', 'O', 'P', 'H', 'M', 'E', 'T', 'A' }
# Version: 64-bit long based on date
# Nonce (IV) Length: 0
# Nonce (IV): randomly generated bytes to use with AES encryption (TODO)
# Blob:	gzipped, mime message bytes. (TODO: add enctyption after V1)
def get_formatted_metadata(gzip_metadata_json):
    return formatterutils.get_formatted_object(
        METADATA_MAGIC_NUMBER,
        SCHEMA_VERSION,
        NONCE_LENGTH,
        gzip_metadata_json
    )

# Read and verify metadata magic number
def is_metadata_file(formatted_s3_metadata_bytes):
    return formatterutils.is_correct_file_format(
        formatted_s3_metadata_bytes,
        METADATA_MAGIC_NUMBER
    )

# Accepts formatted metadata stream downloaded from S3 which has zipped metadata json
# verifies if it is a right type file by magic number and if yes then
# returns unzipped metadata json
def get_metadata_binary(formatted_s3_metadata):
    # verify if it is a metadata file first
    if not is_metadata_file(formatted_s3_metadata[0:9]):
        raise ValueError("Metadata file format error: invalid metadata magic bytes!")

    # Add schema version check with tech debt story: XGE-9131

    if not formatterutils.is_unencypted_data(formatted_s3_metadata[17:21]):
        raise ValueError("Metadata file format error: invalid metadata nonce length bytes!")

    return formatterutils.get_decompressed_object_bytes(
        formatted_s3_metadata[21:len(formatted_s3_metadata)]
    )

