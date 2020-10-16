#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Xgemail Helper class.

Copyright 2020, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import unittest
import rfxrecoveryutils

class XgemailHelperTest(unittest.TestCase):

    def test_is_refelxion_ip(self):
        self.assertFalse(rfxrecoveryutils.is_reflexion_ip("69.85.129.224"))
        self.assertTrue(rfxrecoveryutils.is_reflexion_ip("208.70.208.67"))
        self.assertTrue(rfxrecoveryutils.is_reflexion_ip("208.70.208.68"))
        self.assertTrue(rfxrecoveryutils.is_reflexion_ip("208.70.208.224"))
        self.assertTrue(rfxrecoveryutils.is_reflexion_ip("69.84.129.224"))


    def test_get_direction_for_recovered_mail(self):

        message_headers_inbound = {"X-MRP-Queue": "INBOUND"}
        message_headers_outbound = {"X-MRP-Queue": "OUTBOUND"}
        message_headers_journal = {"X-MRP-Queue": "JOURNAL"}

        direction , is_reply = rfxrecoveryutils.get_direction_for_recovered_mail(message_headers_inbound)
        self.assertEqual(direction,"INBOUND")
        self.assertFalse(is_reply)
        direction , is_reply = rfxrecoveryutils.get_direction_for_recovered_mail(message_headers_outbound)
        self.assertEqual(direction,"OUTBOUND")
        self.assertFalse(is_reply)
        direction , is_reply = rfxrecoveryutils.get_direction_for_recovered_mail(message_headers_journal)
        self.assertEqual(direction,"OUTBOUND")
        self.assertFalse(is_reply)


if __name__ == "__main__":
    unittest.main()