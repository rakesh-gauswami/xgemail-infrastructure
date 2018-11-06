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

import randomutils
import unittest

class RandomUtilsTest(unittest.TestCase):

    def test_roll_the_dice(self):
        probability = 0.50
        for _ in range(0, 25):
            (result, number) = randomutils.roll_the_dice(probability)

            if probability <= number:
                self.assertTrue(result)
            else:
                self.assertFalse(result)

if __name__ == "__main__":
    unittest.main()

