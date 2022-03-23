#!/usr/bin/env python3
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
gets AWS regions containing stations
"""

import argparse

from supported_environment import SUPPORTED_ENVIRONMENT

def main():
    """
    Entry point
    """

    parser = argparse.ArgumentParser(description = "Gets and prints station regions for account")
    parser.add_argument(
        "--account",
        "-a",
        choices = SUPPORTED_ENVIRONMENT.get_legacy_account_names(),
        help = "Valid legacy account",
        required = True
    )

    args = parser.parse_args()

    print(' '.join(SUPPORTED_ENVIRONMENT.get_station_regions(args.account)))

if __name__ == "__main__":
    # execute only if run as a script
    main()
