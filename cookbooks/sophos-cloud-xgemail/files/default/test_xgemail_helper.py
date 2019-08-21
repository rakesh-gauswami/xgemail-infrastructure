#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Xgemail Helper class.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import json
import re
import unittest
import xgemail_helper

class XgemailHelperTest(unittest.TestCase):

    def test_x_sophos_email_id_empty(self):
        self.assertEqual(xgemail_helper.get_x_sophos_email_id(None, "queue_id"), None)

    def test_x_sophos_email_id_invalid(self):
        self.assertEqual(xgemail_helper.get_x_sophos_email_id("Invalid UUID", "queue_id"), None)

    def test_x_sophos_email_id_valid(self):
        self.assertEqual(
            xgemail_helper.get_x_sophos_email_id("e6592dab-ae0e-466c-86b1-c891eda752d8", "queue_id"),
            "e6592dab-ae0e-466c-86b1-c891eda752d8"
        )

    def test_x_sophos_email_id_valid_without_dash(self):
        self.assertEqual(
            xgemail_helper.get_x_sophos_email_id("e6592dabae0e466c86b1c891eda752d8", "queue_id"),
            "e6592dab-ae0e-466c-86b1-c891eda752d8"
        )

if __name__ == "__main__":
    unittest.main()