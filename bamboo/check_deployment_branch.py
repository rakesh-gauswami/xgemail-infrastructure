#!/usr/bin/env python3
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Check branch name against account, ensure prod only gets release branches.
"""

import argparse
import os
import sys

from supported_environment import SUPPORTED_ENVIRONMENT


def check(branch, account):
    """
    Check if ``branch`` can be deployed to ``account``, exit accordingly.
    """

    # pylint: disable=broad-except
    try:
        permitted = SUPPORTED_ENVIRONMENT.get_account(
            account).can_deploy_branch(branch)
    except Exception:
        permitted = False

    if permitted:
        print(
            "Deployment of branch '{}' to account '{}' is permitted.".format(
                branch,
                account
            )
        )
        sys.exit(0)
    else:
        print(
            "Deployment of branch '{}' to account '{}' is NOT permitted.".format(
                branch,
                account
            ),
            file=sys.stderr
        )
        sys.exit(1)


def _main():
    parser = argparse.ArgumentParser(description="Gets and prints region code")
    parser.add_argument(
        "--account",
        "-a",
        help="Specify target account."  # Lack of comma is intentional.
        " Default: value of environment variable 'bamboo_vpc_ACCOUNT'",
        required=True
    )
    parser.add_argument(
        "--branch",
        "-b",
        default=os.environ.get("bamboo_repository_branch_name"),
        help="Specify repository branch."  # Lack of comma is intentional.
        " Default: value of environment variable 'bamboo_repository_branch_name'",
        required=True
    )

    args = parser.parse_args()

    check(args.branch, args.account)


if __name__ == "__main__":
    _main()
