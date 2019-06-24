#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Config Formatter class.

Copyright 2019, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import struct
import json
import unittest
import configformatter
import gziputils

try:
    import mock
except ImportError:
    # Python 2.x doesn't provide the above module as part of its standard library.
    #
    # In order to run this unit test on your local machine, you need to install
    # the mock library as explained here: https://pypi.org/project/mock
    print 'mock library not installed. Skipping these unit tests.'
    sys.exit(0)


class ConfigFormatterTest(unittest.TestCase):

    def test_is_config_file_correct_bytes(self):
        self.assertTrue(configformatter.is_config_file(b'\0SOPHCONFIG'))


    def test_is_config_file_incorrect_bytes(self):
        self.assertFalse(configformatter.is_config_file(b'\0SOPHWRONG'))

    def test_get_binary_with_invalid_bytes(self):
        config_data = {}
        config_data['key1'] = 'val1'
        config_data['key2'] = 'val2'
        config_json = json.dumps(config_data)

        schema_version_bytes = struct.pack("!Q", 20190101)
        nonce_bytes_size = struct.pack("!I", 0)

        binary_content = bytearray(b'\0SOPHWRONG') \
                         + bytearray(schema_version_bytes) \
                         + bytearray(nonce_bytes_size) \
                         + bytearray(gziputils.gzip_data(config_json))

        self.assertRaises(ValueError, configformatter.get_config_binary, binary_content)


    def test_get_binary_with_valid_bytes(self):
        config_data = {}
        config_data['key1'] = 'val1'
        config_data['key2'] = 'val2'
        config_json = json.dumps(config_data)

        schema_version_bytes = struct.pack("!Q", 20190101)
        nonce_bytes_size = struct.pack("!I", 0)

        binary_content = bytearray(b'\0SOPHCONFIG') \
                         + bytearray(schema_version_bytes) \
                         + bytearray(nonce_bytes_size) \
                         + bytearray(gziputils.gzip_data(config_json))

        config_binary_data = configformatter.get_config_binary(binary_content)

        json_content = json.loads(config_binary_data)

        self.assertEqual(json_content['key1'], 'val1')
        self.assertEqual(json_content['key2'], 'val2')


if __name__ == "__main__":
    unittest.main()