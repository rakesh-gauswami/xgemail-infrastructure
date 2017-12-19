#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
Unit tests for the verbatim_option_parser package.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import verbatim_option_parser

import textwrap
import unittest


class VerbatimOptionParserTest(unittest.TestCase):
    TEST_DESCRIPTION = textwrap.dedent("""
    This is some weird formatting.
        Stuff is indented.
        And indented again.
    And unindented.
    - for
    * no
    + good
    / reason.
    """)

    TEST_EPILOG = textwrap.dedent("""
    With a purposeful grimace and a terrible sound
    He pulls the spitting high tension wires down
    Helpless people on a subway train
    Scream bug-eyed as he looks in on them
    He picks up a bus and he throws it back down
    As he wades through the buildings toward the center of town
    Oh no, they say he's got to go go go Godzilla
    Oh no, there goes Tokyo go go Godzilla
    History shows again and again
    How nature points up the folly of men
        - Blue Oyster Cult, "Godzilla"
    """)

    def test_no_exception_if_no_description_or_epilog(self):
        parser = verbatim_option_parser.VerbatimOptionParser()

    def test_description(self):
        parser = verbatim_option_parser.VerbatimOptionParser(
                usage="USAGE",
                description=self.TEST_DESCRIPTION)

        help_text = parser.format_help()

        self.assertTrue(help_text.startswith("Usage: USAGE\n" + self.TEST_DESCRIPTION))

    def test_epilog(self):
        parser = verbatim_option_parser.VerbatimOptionParser(
                usage="USAGE",
                epilog=self.TEST_EPILOG)

        help_text = parser.format_help()

        self.assertTrue(help_text.endswith(self.TEST_EPILOG))

    def test_prog_expansion(self):
        parser = verbatim_option_parser.VerbatimOptionParser(
                prog="PROG",
                usage="%prog [options] [args]",
                description="description/%prog/%prog/",
                epilog="epilog:%prog:%prog:")

        help_text = parser.format_help()

        self.assertTrue(help_text.startswith("Usage: PROG [options] [args]\n\ndescription/PROG/PROG/\n"))
        self.assertTrue(help_text.endswith("\nepilog:PROG:PROG:\n"))

if __name__ == "__main__":
    unittest.main()
