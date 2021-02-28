#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Sophos Central configuration.
"""

import re


# Export constants as functions rather than global variables
# so we can slap a docstring on them.  We could use the global
# docstring instead but then it's harder to make sure each
# item that needs documentation is in fact documented.


def account_ids_dict():
    """
    Return a dict mapping AWS account name to account ID.
    """

    return {
        "dev":      "750199083801",
        "dev2":     "855146673459",
        "dev3":     "769208163330",
        "dev4":     "050963334367",
        "inf":      "283871543274",
        "mr":       "125218878894",
        "qa":       "382702281923",
        "prod":     "202058678495",
    }


def can_deploy_branch(branch, account):
    """
    Return True iff branch ``branch`` may be deployed to account ``account``.

    The primary restriction is that we may only deploy release branches
    to production-like accounts.
    """

    # If we don't know about this account, we can't deploy to it.
    if account not in account_ids_dict():
        return False

    # If it's a dev-like account, we CAN deploy to it.
    if account in dev_accounts_list():
        return True

    # This must be a production-like account, so check the branch
    # to make sure it is permitted.
    valid_release_branch_pattern = r"^release/20\d\d\.\d\d(-[^ ]+)?$"
    valid_release_branch_regex = re.compile(valid_release_branch_pattern)
    if valid_release_branch_regex.match(branch):
        return True

    return False


def dev_accounts_list():
    """
    Return list of dev accounts to which we can deploy any branch.
    Any account not in this list must be treated like production,
    meaning only release and hotfix branches may be deployed to it.
    """

    return "dev dev2 dev3 dev4 inf mr".split()


def prod_accounts_list():
    """
    Return list of prod accounts to which we can deploy release branches.
    """

    return "qa prod".split()


def supported_regions_list():
    """
    Return list of supported AWS regions.
    """

    return [
        "eu-central-1",
        "eu-west-1",
        "us-east-1",
        "us-east-2",
        "us-west-2",
    ]


def supported_vpc_names_list():
    """
    Return a list of VPC names that are valid
    """

    return [
        "CloudEmail",
        "CloudHub",
        "CloudStation"
    ]
