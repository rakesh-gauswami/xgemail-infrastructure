#!/usr/bin/python
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

import optparse
import os
import re
import sys


def parse_command_line():
    parser = optparse.OptionParser(usage="%prog [-a ACCOUNT] [-b BRANCH]")

    parser.add_option(
            "-a", "--account",
            default=os.environ.get("bamboo_vpc_ACCOUNT"),
            help="Specify target account."  # Lack of comma is intentional.
            " Default: value of environment variable 'bamboo_vpc_ACCOUNT'")

    parser.add_option(
            "-b", "--branch",
            default=os.environ.get("bamboo_repository_branch_name"),
            help="Specify repository branch."  # Lack of comma is intentional.
            " Default: value of environment variable 'bamboo_repository_branch_name'")

    options, args = parser.parse_args()

    if len(args) > 0:
        parser.error("too many arguments")

    return options


# Accounts we allow deploying non-release branches to.
DEVELOP_ACCOUNT_NAMES = [
    "dev",      # common dev account
    "dev3",     # scalability
    "dev4",     # leibniz
    "inf",      # infrastructure
    "qainf",    # qa-infrastructure (aka sleeping beauty)
]


# Accounts we must guard against deploying non-release branches to.
PRODUCTION_ACCOUNT_NAMES = [
    "prod",
    "qa",
    "dev5",     # production mirror of days gone by
]


def is_develop_account(account):
    """
    Return True if ``account`` is a known develop account.
    """

    return account in DEVELOP_ACCOUNT_NAMES


def is_production_account(account):
    """
    Return True if ``account`` is a known production account.
    """

    return account in PRODUCTION_ACCOUNT_NAMES


# Regex used to match good release branches.
VALID_RELEASE_BRANCH_PATTERN = r"^release/(CSA-)?201\d\.\d\d(-[^ ]+)?$"
VALID_RELEASE_BRANCH_REGEX = re.compile(VALID_RELEASE_BRANCH_PATTERN)


def is_valid_release_branch(branch):
    return VALID_RELEASE_BRANCH_REGEX.match(branch)


def can_deploy(branch, account):
    """
    Return True if ``branch`` can be deployed to ``account``, else False.

    There are two kinds of accounts, for our purpose: production and develop.

    Production accounts include prod, qa, and dev5.  These accounts are only
    supposed to see code that has been reviewed and tested.  Accordingly,
    we only want to allow release branches to be deployed to them.

    Develop accounts include every account that is not a production account,
    e.g. inf, dev, dev3 (scalability), and dev4 (leibniz).  These are the
    accounts we develop code and infrastructure in, and we must be able to
    deploy any branch to these accounts as we experiment with different
    solutions to different problems.

    If ``account`` is a develop account, we can deploy anything.

    If ``account`` is a production account, we can only deploy release
    branches.

    If ``account`` is neither sort of account, we can deploy nothing.
    """

    if is_develop_account(account):
        return True

    if is_production_account(account):
        if is_valid_release_branch(branch):
            return True

    return False


def check(branch, account):
    """
    Check if ``branch`` cn be deployed to ``account``, exit accordingly.
    """

    permitted = can_deploy(branch, account)
    if permitted:
        print "Deployment of branch '%s' to account '%s' is permitted." % (branch, account)
        sys.exit(0)
    else:
        print >> sys.stderr, "Deployment of branch '%s' to account '%s' is NOT permitted." % (branch, account)
        sys.exit(1)


def _main():
    options = parse_command_line()
    check(options.branch, options.account)


if __name__ == "__main__":
    _main()
