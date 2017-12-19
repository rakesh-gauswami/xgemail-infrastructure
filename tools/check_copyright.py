#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Check for required copyright notice.

This module provides a function to verify that the required copyright notice is present in a file.

More information on format for each file type can be found at:
https://wiki.sophos.net/display/SophosCloud/Sophos+Cloud+Copyright+Templates
"""

import datetime
import os
import sys


default_cr = [ "Copyright YEAR, Sophos Limited. All rights reserved.",
               "'Sophos' and 'Sophos Anti-Virus' are registered trademarks of",
               "Sophos Limited and Sophos Group.  All other product and company",
               "names mentioned are trademarks or registered trademarks of their",
               "respective owners." ]

cookbook_cr = [ "Copyright YEAR, Sophos",
                "All rights reserved - Do Not Redistribute" ]

javascript_cr = [ "Copyright YEAR Sophos Limited. All rights reserved.",
                  "'Sophos' and 'Sophos Anti-Virus' are registered trademarks of Sophos Limited and Sophos Group. All other product",
                  "and company names mentioned are trademarks or registered trademarks of their respective owners." ]


def check_copyright(path, file, copyright, myear, err):
    try:
        rc = True

        copyright = [line.replace("YEAR", str(myear)) for line in copyright]

        for line in copyright:
            if line not in file:
                print >> err, "%s: missing copyright" % path
                rc = False
                break
        return rc
    except Exception as e:
        print >> err, "%s: %s" % (path, e)
        return False


def main():
    paths = sys.argv[1:]

    failed = False
    for path in paths:
        if path.endswith('.3rdparty'):
            continue

        with open(path) as fp:
            file = fp.read().replace('\n','')

            # TODO CDO-457: Be smarter about the expected year.
            # File modification time (os.path.getmtime) will NOT work,
            # as git checkout command does not reset the file modification
            # time to the time that the file was last committed to git.
            continue # WARNING: This DISABLES the check temporarily!!!

            mtime = os.path.getmtime(path)
            myear = datetime.datetime.fromtimestamp(mtime).year

            copyright = default_cr
            if path.endswith('.rb'):
                copyright = cookbook_cr
            elif path.endswith('.js'):
                copyright = javascript_cr

            if not check_copyright(path, file, copyright, myear, sys.stderr):
                failed = True

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
