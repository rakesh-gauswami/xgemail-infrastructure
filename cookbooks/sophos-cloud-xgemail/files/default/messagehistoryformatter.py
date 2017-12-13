# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This script is responsible for formatting metadata object as a message history parent
# document that we store in S3 as described here:
# https://wiki.sophos.net/display/SophosCloud/Message+History+File+Formats

import formatterutils

SCHEMA_VERSION = 20170224
# magic number identifies the file type as message history parent file
MSG_HISTORY_MAGIC_NUMBER = b'\0SOPHHST'
MSG_HISTORY_FILE_EXTENSION = ".PARENT"

# Nonce length is 0 because we are not encrypting data in V1
NONCE_LENGTH = 0

def get_s3_msg_history_path(s3_path):
    return formatterutils.get_s3_file_path(
        s3_path,
        MSG_HISTORY_FILE_EXTENSION
    )

# Binary file format with Big Endian (Network) byte order except encryption
# Magic Bytes:  { '\0', 'S', 'O', 'P', 'H', 'H', 'S', 'T' }
# Version: 64-bit long based on date
# Nonce (IV) Length: 0
# Nonce (IV): randomly generated bytes to use with AES encryption (TODO)
# Blob:	gzipped, mime message bytes. (TODO: add enctyption after V1)
def get_formatted_msg_history(gzip_metadata_json):
    return formatterutils.get_formatted_object(
        MSG_HISTORY_MAGIC_NUMBER,
        SCHEMA_VERSION,
        NONCE_LENGTH,
        gzip_metadata_json
    )

# Read and verify metadata magic number
def is_msg_history_file(formatted_s3_metadata_bytes):
    return formatterutils.is_correct_file_format(
        formatted_s3_metadata_bytes,
        MSG_HISTORY_MAGIC_NUMBER
    )

# Accepts formatted message history stream downloaded from S3 which has zipped metadata json
# verifies if it is a right type file by magic number and if yes then
# returns unzipped metadata json
def get_msg_history_binary(formatted_s3_history_data):
    # verify if it is a metadata file first
    if not is_msg_history_file(formatted_s3_history_data[0:8]):
        raise ValueError("Message history file format error: invalid msg history magic bytes!")

    if not formatterutils.is_correct_version(SCHEMA_VERSION, formatted_s3_history_data[8:16]):
        raise ValueError("Message history file format error: invalid msg history version bytes!")

    if not formatterutils.is_unencypted_data(formatted_s3_history_data[16:20]):
        raise ValueError("Message history file format error: invalid msg history nonce length bytes!")

    return formatterutils.get_decompressed_object_bytes(
        formatted_s3_history_data[20:len(formatted_s3_history_data)]
    )

