#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the check_json utility.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import os
from subprocess import call
from tempfile import NamedTemporaryFile
import unittest

class CheckJsonTest(unittest.TestCase):
    """Unit tests for check_json utility.
    """

    @classmethod
    def setUpClass(cls):
        cls.check_json_path = os.path.join(os.path.dirname(__file__), 'check_json')

        with NamedTemporaryFile(delete=False) as temp_file:
            cls.good_json_file = temp_file.name
            temp_file.write('{ "json_key": "json_value" }')

        with NamedTemporaryFile(delete=False) as temp_file:
            cls.bad_json_file = temp_file.name
            temp_file.write('{ "json_key": "json_value" ')

    def test_good_json(self):
        """Run a known good json file through the checker
        """
        self.assertEquals(call([self.check_json_path, self.good_json_file]), 0)

    def test_bad_json(self):
        """Run a known bad file through the checker
        """
        self.assertNotEquals(call([self.check_json_path, self.bad_json_file]), 0)

    @classmethod
    def tearDownClass(cls):
        os.remove(cls.good_json_file)
        os.remove(cls.bad_json_file)

if __name__ == "__main__":
    unittest.main()
