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
# This script is responsible for formatting a message/email as
# described here: https://wiki.sophos.net/display/SophosCloud/S3+Objects+File+Format

import struct
import gziputils
import hashlib
from datetime import datetime

#constants
NONCE_LENGTH = 0

def get_s3_path(root_dir, timestamp_format, submit_host_ip, queue_id, domain):
    file_path = '%s/%s/%s-%s-%s' % (
        root_dir,
        datetime.now().replace(minute=0, second=0, microsecond=0).strftime(timestamp_format),
        submit_host_ip,
        queue_id,
        domain
    )
    return file_path

def get_s3_file_path(s3_path, extension):
    file_path = '%s%s' % (
        s3_path,
        extension
    )
    return file_path

def get_s3_prefix_file_path(root_dir, queue_id, mailbox_id, submit_host_ip, domain):
    prefix_chars = hashlib.md5(queue_id).hexdigest().lower()[0:4]
    dir_path = '%s/%s/%s/%s-%s-%s' %(
        root_dir,
        prefix_chars,
        mailbox_id,
        submit_host_ip,
        queue_id,
        domain
    )
    return dir_path

# Binary file format with Big Endian byte order except encryption
def get_formatted_object(magic_number, schema_version, nonce_length, gzip_data):
    # 64 bit magic number
    formatted_bytes = magic_number.encode('ascii')
    # 64 bit schema version
    formatted_bytes += struct.pack('!Q',schema_version)
    # 32 bit nonce length
    formatted_bytes += struct.pack('!I',nonce_length)
    # rest gzipped, mime message bytes
    formatted_bytes += gzip_data
    return formatted_bytes

# Read and verify actual magic number matches with expected magic number
# 64 bit magic number
def is_correct_file_format(formatted_magic_bytes, expected_magic_number):
    actual_magic_number = formatted_magic_bytes.decode('ascii')
    if actual_magic_number != expected_magic_number:
        return False
    return True

# Read and verify version number
# 64 bit schema version
def is_correct_version(expected_version, formatted_version_bytes):
    actual_version = struct.unpack('!Q',formatted_version_bytes)[0]
    if actual_version != expected_version:
        return False
    return True

# Read and verify nonce length - 32 bit nonce length
# since in V1 we don't encrypt data
def is_unencypted_data(formatted_nonce_length_bytes):
    actual_nonce_length = struct.unpack('!I',formatted_nonce_length_bytes)[0]
    if actual_nonce_length != NONCE_LENGTH:
        return False
    return True

# rest of the bytes are gzipped data (metadata/message)
def get_decompressed_object_bytes(formatted_object_bytes):
    return gziputils.unzip_data(
        formatted_object_bytes
    )

