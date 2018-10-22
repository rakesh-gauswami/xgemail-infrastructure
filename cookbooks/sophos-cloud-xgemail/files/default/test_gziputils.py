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

import gziputils
import json
import unittest

class GZipUtilsTest(unittest.TestCase):
    data = json.dumps({'key': 'value'})

    def test_zip_unzip_data(self):
        gzipped_data = gziputils.gzip_data(self.data)

        self.assertNotEquals(self.data, gzipped_data)

        unzipped_data = gziputils.unzip_data(gzipped_data)

        self.assertEquals(self.data, unzipped_data)

if __name__ == "__main__":
    unittest.main()
