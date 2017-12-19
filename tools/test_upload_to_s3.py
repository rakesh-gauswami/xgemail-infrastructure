#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the upload_to_s3 utility.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import upload_to_s3

import unittest


class Update3rdpartyPackageTest(unittest.TestCase):
    """
    Unit tests for upload_to_s3 utility..
    """

    def test_get_key(self):
        # In the happy case path will also be present,
        # but the folder may be empty, /, or something longer.
        self.assertEqual(upload_to_s3.get_key("", "path"), "path")
        self.assertEqual(upload_to_s3.get_key("/", "path"), "path")
        self.assertEqual(upload_to_s3.get_key("dir", "path"), "dir/path")
        self.assertEqual(upload_to_s3.get_key("/dir", "path"), "dir/path")
        self.assertEqual(upload_to_s3.get_key("dir/", "path"), "dir/path")
        self.assertEqual(upload_to_s3.get_key("/dir/", "path"), "dir/path")
        self.assertEqual(upload_to_s3.get_key("dir/sub", "path"), "dir/sub/path")
        self.assertEqual(upload_to_s3.get_key("/dir/sub", "path"), "dir/sub/path")
        self.assertEqual(upload_to_s3.get_key("dir/sub/", "path"), "dir/sub/path")
        self.assertEqual(upload_to_s3.get_key("/dir/sub/", "path"), "dir/sub/path")

if __name__ == "__main__":
    unittest.main()
