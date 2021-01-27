#!/usr/bin/env python
# vim: autoindent expandtab shiftwidth=4 filetype=python

# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Test sophos.subcommands module.
"""

# Import test module FIRST to make sure there are no dependencies.
import sophos.subcommands

import cStringIO as StringIO
import mock
import textwrap
import unittest

import sophos.testing

class SubcommandsTest(unittest.TestCase):
    """Test sophos.subcommands module."""

    # Generate test methods from classmethods whose names start with "gen_".
    __metaclass__ = sophos.testing.TestGenerator

    def check_parse_docstring(self, docstring, description, epilog):
        """Check return value of sophos.subcommands.parse_docstring agains expected values."""

        actual = sophos.subcommands.parse_docstring(docstring)
        expected = (description, epilog)
        self.assertEqual(actual, expected)

    @classmethod
    def gen_parse_docstring_tests(cls):
        """Generate test methods for sophos.subcommands.parse_docstring."""

        cases = [
            # (input docstring, expected description, expected epilog)

            # Return None for missing docstring and epilog.
            (None, None, None),
            ("", None, None),
            ("description only", "description only", None),

            # Handle docstring without leading or trailing newlines.
            (
                """description line
                epilog line""",
                "description line",
                "epilog line"
            ),
            (
                """description line
                epilog line
                more""",
                "description line",
                "epilog line\nmore"
            ),

            # Handle docstring with leading or trailing newlines
            # and various amount of extra whitespace.
            (
                """
                description line
                epilog line
                """,
                "description line",
                "epilog line"
            ),
            (
                """
                description line

                epilog line
                """,
                "description line",
                "epilog line"
            ),
            (
                """

                description line

                epilog line

                """,
                "description line",
                "epilog line"
            ),
            (
                """

                description line

                epilog line1
                epilog line2

                """,
                "description line",
                "epilog line1\nepilog line2"
            ),
            (
                """

                description line

                epilog line1

                  epilog line2 (indented)

                """,
                "description line",
                "epilog line1\n\n  epilog line2 (indented)"
            ),
        ]

        for case in cases:
            docstring, description, epilog = case
            yield cls.check_parse_docstring, docstring, description, epilog


    def test_run_command_not_given(self):
        """Test run() with no command specified on the command line."""

        with mock.patch("sys.argv", new=["myprog"]):
            with mock.patch("sys.stdout", new=StringIO.StringIO()) as fake_out:
                with mock.patch("sys.stderr", new=StringIO.StringIO()) as fake_err:
                    with self.assertRaises(SystemExit) as cm:
                        sophos.subcommands.run([])

        self.assertEqual(fake_out.getvalue(), "")
        self.assertEqual(fake_err.getvalue(), "myprog: missing command argument, run 'myprog --help' for details\n")
        self.assertEqual(cm.exception.code, 1)


    def test_run_command_not_unregistered(self):
        """Test run() with unregistered command specified on the command line."""

        with mock.patch("sys.argv", new=["myprog", "bogus"]):
            with mock.patch("sys.stdout", new=StringIO.StringIO()) as fake_out:
                with mock.patch("sys.stderr", new=StringIO.StringIO()) as fake_err:
                    with self.assertRaises(SystemExit) as cm:
                        sophos.subcommands.run([])

        self.assertEqual(fake_out.getvalue(), "")
        self.assertEqual(fake_err.getvalue(), "myprog: invalid command 'bogus', run 'myprog --help' for details\n")
        self.assertEqual(cm.exception.code, 1)


    def test_run_a_command(self):
        """Test run() with a registered command."""

        def echo(parser, argv):
            """Echo arguments."""
            parser.add_argument("words", nargs="+")
            args = parser.parse_args(argv)
            print " ".join(args.words)

        def add(parser, argv):
            """Add arguments."""
            parser.add_argument("numbers", nargs="+")
            args = parser.parse_args(argv)
            print sum(map(float, args.numbers))

        subcommands = [ echo, add ]

        with mock.patch("sys.argv", new=["myprog", "echo", "ic", "wot", "u", "meen"]):
            with mock.patch("sys.stdout", new=StringIO.StringIO()) as fake_out:
                with mock.patch("sys.stderr", new=StringIO.StringIO()) as fake_err:
                    sophos.subcommands.run(subcommands)

        self.assertEqual(fake_out.getvalue(), "ic wot u meen\n")
        self.assertEqual(fake_err.getvalue(), "")

        with mock.patch("sys.argv", new=["myprog", "add", "3.14", "2.718", "-40", "137"]):
            with mock.patch("sys.stdout", new=StringIO.StringIO()) as fake_out:
                with mock.patch("sys.stderr", new=StringIO.StringIO()) as fake_err:
                    sophos.subcommands.run(subcommands)

        self.assertEqual(fake_out.getvalue(), "102.858\n")
        self.assertEqual(fake_err.getvalue(), "")


    def test_run_help_empty_command_list(self):
        """Test run() with help command but no registered commands."""

        with mock.patch("sys.argv", new=["myprog", "help"]):
            with mock.patch("sys.stdout", new=StringIO.StringIO()) as fake_out:
                with mock.patch("sys.stderr", new=StringIO.StringIO()) as fake_err:
                    with self.assertRaises(SystemExit) as cm:
                        sophos.subcommands.run([])

        self.assertEqual(fake_out.getvalue(), textwrap.dedent("""
            usage: myprog <command> [<args>]

            available commands:
              help          Print list of subcommands or detailed help for a single subcommand
            """).lstrip("\n"))

        self.assertEqual(fake_err.getvalue(), "")
        self.assertEqual(cm.exception.code, 0)


    def test_run_help_populated_command_list(self):
        """Test run() with help command and some registered commands."""

        def foo(parser, argv):
            """Do the foo"""
            pass

        def bar(parser, argv):
            """Do the bar"""
            pass

        subcommands = [ foo, bar ]

        with mock.patch("sys.argv", new=["myprog", "help"]):
            with mock.patch("sys.stdout", new=StringIO.StringIO()) as fake_out:
                with mock.patch("sys.stderr", new=StringIO.StringIO()) as fake_err:
                    with self.assertRaises(SystemExit) as cm:
                        sophos.subcommands.run(subcommands)

        self.assertEqual(fake_out.getvalue(), textwrap.dedent("""
            usage: myprog <command> [<args>]

            available commands:
              help          Print list of subcommands or detailed help for a single subcommand
              foo           Do the foo
              bar           Do the bar
            """).lstrip("\n"))

        self.assertEqual(fake_err.getvalue(), "")
        self.assertEqual(cm.exception.code, 0)


    def test_run_help_for_command(self):
        """Test run() with help command against a registered command."""

        def frozzle(parser, argv):
            '''frozzle the glotchkin'''
            parser.parse_args(argv)
            print "time to frozzle the glotchkin!"

        def snozzle(parser, argv):
            '''
            snozzle a file
            Snozzling a file just means printing it.
            '''
            parser.add_argument("path")
            args = parser.parse_args(argv)
            with open(args.path) as fp:
                print fp.read()

        subcommands = [ frozzle, snozzle ]

        with mock.patch("sys.argv", new=["myprog", "help", "snozzle"]):
            with mock.patch("sys.stdout", new=StringIO.StringIO()) as fake_out:
                with mock.patch("sys.stderr", new=StringIO.StringIO()) as fake_err:
                    with self.assertRaises(SystemExit) as cm:
                        sophos.subcommands.run(subcommands)

        self.assertEqual(fake_out.getvalue(), textwrap.dedent("""
            usage: myprog snozzle [-h] path

            snozzle a file

            positional arguments:
              path

            optional arguments:
              -h, --help  show this help message and exit

            Snozzling a file just means printing it.
            """).lstrip("\n"))

        self.assertEqual(fake_err.getvalue(), "")
        self.assertEqual(cm.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
