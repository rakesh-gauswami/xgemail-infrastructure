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
# This script is responsible for compression and decompression of bytes stream using gzip

import gzip
import io

# return gzipped bytes
def gzip_data(data):
    compressed_bytes = None

    data_bytesio = io.BytesIO()

    try:
        gzip_file = gzip.GzipFile(fileobj=data_bytesio, mode='wb')

        try:
            gzip_file.write(data)
        finally:
            gzip_file.close()

        compressed_bytes = data_bytesio.getvalue()
    finally:
        data_bytesio.close()

    return compressed_bytes

# return un-gzipped bytes
def unzip_data(data):
    decompressed_bytes = None

    data_bytesio = io.BytesIO(data)

    try:
        decompressed_file = gzip.GzipFile(fileobj=data_bytesio, mode='rb')

        try:
            decompressed_bytes = decompressed_file.read()
        finally:
            decompressed_file.close()
    finally:
        data_bytesio.close()

    return decompressed_bytes
