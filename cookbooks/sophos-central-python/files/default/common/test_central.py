#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Test sophos.central module.
"""

# Import test module FIRST to make sure there are no dependencies.
import sophos.central

import unittest


class AwsConfigTest(unittest.TestCase):
    def test_account_ids_dict(self):
        account_ids_dict = sophos.central.account_ids_dict()

        self.assertIsInstance(account_ids_dict, dict)

        for account, account_id in account_ids_dict.items():
            # Account names must be given in lower case.
            self.assertIsInstance(account, str)
            self.assertEqual(account, account.lower())
            # Account IDs are 12-digit numbers encoded as strings.
            self.assertIsInstance(account_id, str)
            self.assertRegexpMatches(account_id, r"^\d{12}$")

    def test_can_deploy_branch(self):
        account_branch_expected_data = [
            # Accounts we don't know how to characterize:
            ("foo",     "develop",                  False),
            ("foo",     "feature/CPLAT-14201",      False),
            ("foo",     "bugfix/CPLAT-14201",       False),
            ("foo",     "hotfix/CPLAT-14201",       False),
            ("foo",     "release/2016.37",          False),
            ("foo",     "release/2016.37-more",     False),

            # Dev-like accounts we can deploy anything to:
            ("dev",     "develop",                  True),
            ("dev",     "feature/CPLAT-14201",      True),
            ("dev",     "bugfix/CPLAT-14201",       True),
            ("dev",     "hotfix/CPLAT-14201",       True),
            ("dev",     "release/2016.37",          True),
            ("dev",     "release/2016.37-more",     True),
            ("inf",     "develop",                  True),
            ("inf",     "feature/CPLAT-14201",      True),
            ("inf",     "bugfix/CPLAT-14201",       True),
            ("inf",     "hotfix/CPLAT-14201",       True),
            ("inf",     "release/2016.37",          True),
            ("inf",     "release/2016.37-more",     True),

            # Prod-like accounts, non-release branches:
            ("prod",    "bugfix/CPLAT-14201",       False),
            ("prod",    "develop",                  False),
            ("prod",    "feature/CPLAT-14201",      False),
            ("prod",    "hotfix/CPLAT-14201",       False),
            ("qa",      "bugfix/CPLAT-14201",       False),
            ("qa",      "develop",                  False),
            ("qa",      "feature/CPLAT-14201",      False),
            ("qa",      "hotfix/CPLAT-14201",       False),

            # Prod-like accounts, release branches:
            ("prod",    "release/2016.37",          True),
            ("prod",    "release/2016.37-more",     True),
            ("qa",      "release/2016.37",          True),
            ("qa",      "release/2016.37-more",     True),

            # Prod-like accounts, not-quite-release branches:
            ("prod",    "release",                  False),
            ("prod",    "release-2016.31",          False),
            ("prod",    "Release/2016.31",          False),
            ("prod",    "release/1016,31",          False),
            ("prod",    "release/1016,314",         False),
            ("prod",    "release/1016.31",          False),
            ("prod",    "release/bad",              False),
            ("qa",      "release",                  False),
            ("qa",      "release-2016.31",          False),
            ("qa",      "Release/2016.31",          False),
            ("qa",      "release/1016,31",          False),
            ("qa",      "release/1016,314",         False),
            ("qa",      "release/1016.31",          False),
            ("qa",      "release/bad",              False),
        ]

        for account, branch, expected in account_branch_expected_data:
            actual = sophos.central.can_deploy_branch(branch, account)
            self.assertEqual(actual, expected, "account: %s, branch: %s, expected: %s, actual: %s" % (account, branch, expected, actual))

    def test_dev_accounts_list(self):
        dev_accounts_list = sophos.central.dev_accounts_list()

        self.assertIsInstance(dev_accounts_list, list)

        for account in dev_accounts_list:
            # Account names must be given in lower case.
            self.assertIsInstance(account, str)
            self.assertEqual(account, account.lower())

        # Things we know count as development accounts:
        self.assertIn("dev", dev_accounts_list)
        self.assertIn("dev2", dev_accounts_list)
        self.assertIn("dev3", dev_accounts_list)
        self.assertIn("dev4", dev_accounts_list)
        self.assertIn("inf", dev_accounts_list)
        self.assertIn("mr", dev_accounts_list)

        # Things we know don't count as development accounts:
        self.assertNotIn("prod", dev_accounts_list)
        self.assertNotIn("qa", dev_accounts_list)

        # Neither development nor production:
        self.assertNotIn("hmr-core", dev_accounts_list)

    def test_prod_accounts_list(self):
        prod_accounts_list = sophos.central.prod_accounts_list()

        self.assertIsInstance(prod_accounts_list, list)

        for account in prod_accounts_list:
            # Account names must be given in lower case.
            self.assertIsInstance(account, str)
            self.assertEqual(account, account.lower())

        # Things we know count as production accounts:
        self.assertIn("prod", prod_accounts_list)
        self.assertIn("qa", prod_accounts_list)

        # Things we know don't count as production accounts:
        self.assertNotIn("dev", prod_accounts_list)
        self.assertNotIn("dev2", prod_accounts_list)
        self.assertNotIn("dev3", prod_accounts_list)
        self.assertNotIn("dev4", prod_accounts_list)
        self.assertNotIn("inf", prod_accounts_list)
        self.assertNotIn("mr", prod_accounts_list)

        # Neither development nor production:
        self.assertNotIn("hmr-core", prod_accounts_list)

    def test_supported_regions_list(self):
        supported_regions_list = sophos.central.supported_regions_list()

        self.assertIsInstance(supported_regions_list, list)

        for region in supported_regions_list:
            # Region names must be given in lower case.
            self.assertIsInstance(region, str)
            self.assertEqual(region, region.lower())

        self.assertIn("eu-central-1", supported_regions_list)
        self.assertIn("eu-west-1", supported_regions_list)
        self.assertIn("us-east-1", supported_regions_list)
        self.assertIn("us-east-2", supported_regions_list)
        self.assertIn("us-west-2", supported_regions_list)


if __name__ == "__main__":
    unittest.main()
