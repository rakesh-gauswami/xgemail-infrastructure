#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

__author__ = 'sophos-email-dev-burlington@sophos.com'

"""
Script that allows creation of arbitrarily large allow/block CSV file.
This script is mainly used to support testing of allow/block import feature.

Copyright 2019, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import argparse
import string
import random

RANDOM_STRING_LENGTH = 10

def get_random_string(size = RANDOM_STRING_LENGTH, chars = string.ascii_uppercase + string.digits):
    """
    Returns a randomized string
    """
    return ''.join(random.choice(chars) for unused in range(size))

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(
        description = 'Script that allows creation of arbitrarily large allow/block CSV file',
        epilog='python {0} --a email@domain.com 5 BLOCK --e 10 ALLOW'.format(__file__)
    )

    parser.add_argument('-o', '--output', dest = 'output_file', default = '/tmp/random-allow-block-entries.csv', help = 'Path (including file name) to resulting .csv file')
    parser.add_argument('-a', '--address', dest = 'addresses', nargs=3, action = 'append', help = 'Allow/block entries for email addresses')
    parser.add_argument('-e', '--enterprise', dest = 'enterprises', nargs=2, action = 'append', help = 'Allow/block entries for enterprises')

    args = parser.parse_args()

    if (not args.enterprises or len(args.enterprises) == 0) and (not args.addresses or len(args.addresses) == 0):
        parser.error('No arguments provided.')

    with open(args.output_file, 'w+') as output:
        # add header line
        output.write('User Email/Enterprise, Allow/Block, EmailAddress/Domain\n')

        if args.enterprises:
            for cur_entry in args.enterprises:
                nr_of_aliases = int(cur_entry[0])
                entry_type = cur_entry[1]
                entry = 'Enterprise, {0}'.format(entry_type)
                for cur_nr in range(nr_of_aliases):
                    entry += ', {0}-{1}@{2}.com'.format(cur_nr, get_random_string(), get_random_string())
                output.write(entry + '\n')

        if args.addresses:
            for cur_entry in args.addresses:
                address = cur_entry[0]
                nr_of_aliases = int(cur_entry[1])
                entry_type = cur_entry[2]

                entry = '{0}, {1}'.format(address, entry_type)
                for cur_nr in range(nr_of_aliases):
                    entry += ', {0}-{1}@{2}.com'.format(cur_nr, get_random_string(), get_random_string())
                output.write(entry + '\n')

    print open(args.output_file, 'r').read()
