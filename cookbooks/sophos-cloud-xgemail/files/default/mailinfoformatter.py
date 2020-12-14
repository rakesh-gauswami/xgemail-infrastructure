# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2020, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This script is responsible for formatting mailinfo object and storing it in S3 as described here:
# https://wiki.sophos.net/display/SophosCloud/Message+History+File+Formats

import formatterutils

# magic number identifies the file type as mail info file
MAIL_INFO_MAGIC_NUMBER = b'\0SOPHMINF'
MAIL_INFO_FILE_EXTENSION = ".MAIL_INFO"

# Nonce length is 0 because we are not encrypting data in V1
NONCE_LENGTH = 0

def get_mail_info_path(s3_path):
    return formatterutils.get_s3_file_path(
        s3_path,
        MAIL_INFO_FILE_EXTENSION
    )

# Binary file format with Big Endian (Network) byte order except encryption
# Magic Bytes:  { '\0', 'S', 'O', 'P', 'H', 'M','I', 'N', 'F' }
# Version: 64-bit long based on date
# Blob:	gzipped, mime message bytes.
def get_formatted_mail_info(gzip_metadata_json, schema_version):
    return formatterutils.get_formatted_object(
        MAIL_INFO_MAGIC_NUMBER,
        schema_version,
        NONCE_LENGTH,
        gzip_metadata_json
    )

# Read and verify metadata magic number
def is_mh_mail_info_file(formatted_s3_metadata_bytes):
    return formatterutils.is_correct_file_format(
        formatted_s3_metadata_bytes,
        MAIL_INFO_MAGIC_NUMBER
    )
