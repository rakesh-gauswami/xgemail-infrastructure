#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Check files for ansible vault encryption header.
"""

import re
import sys


def check_vaulted(path, text, err):
    if text is None or text == "":
        print >> err, "%s:0: no content" % path
        return False

    lines = text.splitlines()

    for i, line in enumerate(lines):
        lineno = i + 1
        if i == 0:
            if line != "$ANSIBLE_VAULT;1.1;AES256":
                print >> err, "%s:%d: no leading vault header" % (path, lineno)
                return False
        else:
            if not re.match(r"^[a-z0-9]+$", line):
                print >> err, "%s:%d: unexpected content" % (path, lineno)
                return False

    return True


def main():
    # Process every file on listed on the command line so that we report all
    # failing files, not just the first one we find.

    paths = sys.argv[1:]

    failed = False
    for path in paths:
        with open(path) as fp:
            text = fp.read()
            if not check_vaulted(path, text, sys.stderr):
                failed = True

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
