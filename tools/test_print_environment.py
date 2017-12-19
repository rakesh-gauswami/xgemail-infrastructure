#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the print_environment utility.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import print_environment

import unittest


class PrintEnvironmentTest(unittest.TestCase):
    """
    Unit tests for the print_environment utility.
    """

    def check_matches(self, candidates, patterns, result):
        self.assertEqual(
                print_environment.matches(candidates, patterns),
                result)

    def test_no_patterns_or_candidates(self):
        self.check_matches([], [], [])

    def test_no_patterns_matches_all_candidates(self):
        self.check_matches(["Z", "A", "M"], [], ["A", "M", "Z"])

    def test_single_pattern_matches_no_candidates(self):
        self.check_matches(["ZB", "AB", "MC"], ["F"], [])
        self.check_matches(["ZB", "AB", "MC"], ["^F"], [])
        self.check_matches(["ZB", "AB", "MC"], ["F$"], [])

    def test_single_pattern_matches_some_candidates(self):
        self.check_matches(["ZB", "AB", "MC"], ["A"], ["AB"])
        self.check_matches(["ZB", "AB", "MC"], ["^A"], ["AB"])
        self.check_matches(["ZB", "AB", "MC"], ["B$"], ["AB", "ZB"])

    def test_many_patterns_match_no_candidates(self):
        self.check_matches(["Z", "A", "M"], ["Y", "[B-L]"], [])

    def test_many_patterns_match_overlapping_candidates(self):
        self.check_matches(["Z", "A", "M"], ["[A-M]", "[B-Q]"], ["A", "M"])

if __name__ == "__main__":
    unittest.main()
