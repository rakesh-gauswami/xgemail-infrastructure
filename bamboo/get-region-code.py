#!/usr/bin/env python3
# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
gets AWS region code
"""

import argparse

from supported_environment import SUPPORTED_ENVIRONMENT

def main():
    """
    Entry point
    """

    parser = argparse.ArgumentParser(description = "Gets and prints region code")
    parser.add_argument(
        "--region",
        "-r",
        help = "Valid supported region %s" % SUPPORTED_ENVIRONMENT.aws_regions,
        required = True
    )

    args = parser.parse_args()

    print( SUPPORTED_ENVIRONMENT.get_region_code(args.region))

if __name__ == "__main__":
    # execute only if run as a script
    main()
