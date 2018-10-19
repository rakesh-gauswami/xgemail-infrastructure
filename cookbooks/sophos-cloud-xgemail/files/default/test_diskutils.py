#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Xgemail diskutils utility.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import diskutils
import tempfile
import unittest

from notadirectoryexception import NotADirectoryException

class DiskUtilsTest(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.empty_dir = tempfile.mkdtemp()

    def test_is_directory_empty_with_None(self):
        with self.assertRaises(NotADirectoryException):
            diskutils.is_directory_empty(None)

    def test_is_directory_empty_with_invalid_directory(self):
        with self.assertRaises(NotADirectoryException):
            diskutils.is_directory_empty('/tmp/xgemail-does-not-exist')

    def test_is_directory_empty_with_existing_empty_directory(self):
        self.assertFalse(diskutils.is_directory_empty(self.empty_dir))

    def test_is_directory_empty_with_existing_non_empty_directory(self):
        self.assertFalse(diskutils.is_directory_empty('.'))

if __name__ == "__main__":
    unittest.main()
