#!/usr/bin/env python
# vim: autoindent expandtab shiftwidth=4 filetype=python

# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Support for subcommand argument parsers, like git and docker.

This module provides support for defining subcommands and selecting
them on the command-line.

Each subcommand should be defined using a function that takes two arguments,
an argument parser object (an instance of argparse.ArgumentParser) and
an argument vector.

Subcommands are responsible for calling the parser's parse_args method,
passing the supplied argument vector.

Help messages for each subcommand will be extracted from the docstring.

For example:

    # No need to provide a help command, one will be generated
    # from the provided subcommands.

    # Example of a subcommand that takes no arguments.
    def frozzle(parser, argv):
        '''frozzle the glotchkin'''
        parser.parse_args(argv)
        print "time to frozzle the glotchkin!"

    # Example of a subcommand that take an argument.
    def snozzle(parser, argv):
        '''
        snozzle a file
        Snozzling a file just means printing it.
        '''
        parser.add_argument("path")
        args = parser.parse_args(argv)
        with open(args.path) as fp:
           print fp.read()

    if __name__ == "__main__":
        import sophos.subcommands

        # List commands in the order we would like the help command to display them.
        commands = [
            frozzle,
            snozzle,
        ]

        # This either returns the return value of the executed command
        # or prints an error message to sys.stderr and exits.
        sophos.subcommands.run(commands, description="frozzle or snozzle")

Command functions can be namespaced by making them static methods in a class.

For example:

    class Commands(object):
        @staticmethod
        def foo(parser, argv):
            ...

        @staticmethod
        def bar(parser, argv):
            ...

    commands = [ Commands.foo, Commands.bar ]

    sophos.subcommands.run(commands, ...)

"""

import argparse
import copy
import os
import sys
import textwrap


def parse_docstring(docstring):
    """Return (description, epilog) tuple from a python docstring.
    description is just the first non-blank line.
    epilog is the remaining non-blank lines.
    """

    if docstring is None:
        return (None, None)

    doclines = docstring.strip().splitlines()
    if len(doclines) == 0:
        return (None, None)

    description = doclines[0]

    epilog = textwrap.dedent(("\n".join(doclines[1:]))).strip() or None

    return (description, epilog)


def _print_command_description(name, description):
    if description is None:
        print "  %s" % name
    else:
        print "  %-13s %s" % (name, description)


def _get_help_command(subcommands, prog, usage):
    """Create help command that knows about all subcommands, including itself."""

    def help(parser, argv):
        """Print list of subcommands or detailed help for a single subcommand"""

        parser.add_argument("command", help="subcommand to print help for", nargs="?")

        args = parser.parse_args(argv)

        # Note: convention is for help function to exit rather than return a value.
        # Caller can catch SystemExit exception if necessary.

        if args.command is None:
            print "usage:", usage
            print
            print "available commands:"
            for subcommand in subcommands:
                name = subcommand.__name__
                description, _ = parse_docstring(subcommand.__doc__)
                _print_command_description(name, description)
            sys.exit(0)

        if "help" == args.command:
            _run_subcommand(prog, help, ["--help"])
            sys.exit(0)

        for subcommand in subcommands:
            if subcommand.__name__ == args.command:
                _run_subcommand(prog, subcommand, ["--help"])
                sys.exit(0)

        print >> sys.stderr, "%s: invalid command %r, run '%s --help' for details" % (prog, args.command, prog)
        sys.exit(1)

    return help


def _run_subcommand(prog, subcommand, argv):
    """Create ArgumentParser and argv for subcommand and run it."""

    description, epilog = parse_docstring(subcommand.__doc__)

    parser = argparse.ArgumentParser(
            prog=prog + " " + subcommand.__name__,
            description=description,
            epilog=epilog,
            formatter_class=argparse.RawDescriptionHelpFormatter)

    return subcommand(parser, argv)


def run(subcommands, prog=None, description=None, epilog=None):
    """
    Run subcommand named on command line.

    Positional arguments:
      - subcommands -- List of callable subcommand objects.
        Each subcommand must have a __name__ attribute.
        Each subcommand may have a __doc__ attribute.
        Each subcommand must take parser and argv arguments.

    Keyword arguments:
      - prog -- The name of the program (default: sys.argv[0])
      - description -- A description of what the program does
      - epilog -- Text following the argument descriptions

    Returns the return value of the executed subcommand, or
    prints an error messages to sys.stderr and exits.
    """

    if prog is None:
        prog = os.path.basename(sys.argv[0])

    usage = "%s <command> [<args>]" % prog

    if epilog is None:
        epilog = "Run '%s help' for a list of commands." % prog

    parser = argparse.ArgumentParser(
            prog=prog,
            usage=usage,
            description=description,
            epilog=epilog,
            formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument("command", help="subcommand to run")

    if len(sys.argv) == 1:
        print >> sys.stderr, "%s: missing command argument, run '%s --help' for details" % (prog, prog)
        sys.exit(1)

    # Initial parse should capture just the command name,
    # or the -h/--help option.
    args = parser.parse_args(sys.argv[1:2])

    # Make local copy of subcommands and prepend help command to it.
    # This lets the help command see a list of commands that includes itself.
    subcommands_with_help = copy.copy(subcommands)
    subcommands_with_help.insert(0, _get_help_command(subcommands_with_help, prog, usage))

    # Look for specified command and run it, passing remaining command-line arguments.
    for subcommand in subcommands_with_help:
        if subcommand.__name__ == args.command:
            return _run_subcommand(prog, subcommand, sys.argv[2:])

    print >> sys.stderr, "%s: invalid command %r, run '%s --help' for details" % (prog, args.command, prog)
    sys.exit(1)
