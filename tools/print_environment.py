#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
Print environment variables to stdout, sorted and escaped.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import json
import os
import re


def parse_command_line():
    import optparse

    parser = optparse.OptionParser(
            usage="%prog [PATTERN(s)]")

    options, patterns = parser.parse_args()

    return patterns


def matches(candidates, patterns):
    """
    Return a sorted list of items in candidates that match one of more patterns.
    If no patterns are given then return all candidates.
    """

    if len(patterns) == 0:
        return sorted(list(candidates))

    matches = set([])
    for pattern in patterns:
        prog = re.compile(pattern)
        for candidate in candidates:
            if prog.search(candidate):
                matches.add(candidate)

    return sorted(list(matches))


if __name__ == "__main__":
    patterns = parse_command_line()
    keys = matches([k for k in os.environ], patterns)
    for key in keys:
        val = os.environ[key]
        print "%s=%s" % (key, json.dumps(val))
