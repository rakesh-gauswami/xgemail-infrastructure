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
import json

from supported_environment import SUPPORTED_ENVIRONMENT

def main():
    """
    Entry point
    """

    parser = argparse.ArgumentParser(description = "Parses PoP account name and outputs JSON")
    parser.add_argument(
        "--account",
        "-a",
        choices = SUPPORTED_ENVIRONMENT.get_pop_account_names(),
        help = "PoP account name",
        required = True
    )

    args = parser.parse_args()

    pop_account = SUPPORTED_ENVIRONMENT.get_pop_account(args.account)

    ret_val = {
        'account': args.account,
        'account_id': pop_account.get_account_id(),
        'deployment_environment': pop_account.get_deployment_environment(),
        'parent_account_id': pop_account.get_parent_account_id(),
        'region': pop_account.get_primary_region(),
        'type': pop_account.get_account_type()
    }

    print(json.dumps(ret_val, indent = 2))

if __name__ == "__main__":
    # execute only if run as a script
    main()
