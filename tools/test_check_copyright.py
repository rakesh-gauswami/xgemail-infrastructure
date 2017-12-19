#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Unit tests for the check_copyright utility.

"""

import check_copyright
import cStringIO
import unittest


class CheckCopyrightTest(unittest.TestCase):

    def test_cookbook_file(self):
        err = cStringIO.StringIO()

        self.assertTrue(check_copyright.check_copyright("default.rb", """
        Copyright 2014, Sophos
        All rights reservered - Do Not Redistribute
        """, "Copyright 2014, Sophos", "2014", err))
        self.assertEqual(err.getvalue(), "")

    def test_default_file(self):
        copyright = [ "Copyright YEAR, Sophos Limited. All rights reserved.",
                       "'Sophos' and 'Sophos Anti-Virus' are registered trademarks of",
                       "Sophos Limited and Sophos Group.  All other product and company",
                       "names mentioned are trademarks or registered trademarks of their",
                       "respective owners." ]
        err = cStringIO.StringIO()

        self.assertTrue(check_copyright.check_copyright("default.py", """
        Copyright 2015, Sophos Limited. All rights reserved.
        'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
        Sophos Limited and Sophos Group.  All other product and company
        names mentioned are trademarks or registered trademarks of their
        respective owners.
        """, copyright, "2015", err))
        self.assertEqual(err.getvalue(), "")

    def test_empty_file(self):
        err = cStringIO.StringIO()

        self.assertFalse(check_copyright.check_copyright("default.py", "", "Copyright 2016, Sophos", "2016", err))
        self.assertEqual(err.getvalue().replace('\n',''), "default.py: missing copyright")

    def test_copyright_year(self):
        err = cStringIO.StringIO()

        self.assertFalse(check_copyright.check_copyright("default.rb", """
        Copyright 2015, Sophos
        All rights reservered - Do Not Redistribute
        """, "Copyright YEAR, Sophos", "2016", err))
        self.assertEqual(err.getvalue().replace('\n',''), "default.rb: missing copyright")

if __name__ == "__main__":
    unittest.main()
