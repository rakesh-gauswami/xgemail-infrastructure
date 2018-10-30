#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python
#
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import json
from os import path
import shutil
import tempfile
import unittest

from recipientsplitconfig import RecipientSplitConfig

class RecipientSplitConfigTest(unittest.TestCase):
    valid_config_globally_enabled = {
        'is_globally_enabled': True,
        'customer_ids_enabled': [
            '84e61a73-5e3b-4616-8719-6098a0cb0ede',
            '99e61a73-5e3b-4616-8719-6098a0cb0ede'
        ]
    }

    valid_config_globally_not_enabled = {
        'is_globally_enabled': False,
        'customer_ids_enabled': [
            '84e61a73-5e3b-4616-8719-6098a0cb0ede',
            '99e61a73-5e3b-4616-8719-6098a0cb0ede'
        ]
    }

    invalid_config_missing_field = {
        'customer_ids_enabled': [
            '84e61a73-5e3b-4616-8719-6098a0cb0ede',
            '99e61a73-5e3b-4616-8719-6098a0cb0ede'
        ]
    }

    def setUp(self):
        # create a temporary directory
        self.test_dir = tempfile.mkdtemp()

        self.valid_config_globally_enabled_file = path.join(
            self.test_dir,
            'valid_config_globally_enabled.json'
        )

        with open(self.valid_config_globally_enabled_file, 'w') as config_file:
            config_file.write(json.dumps(self.valid_config_globally_enabled))

        self.valid_config_globally_not_enabled_file = path.join(
            self.test_dir,
            'valid_config_globally_not_enabled_file.json'
        )

        with open(self.valid_config_globally_not_enabled_file, 'w') as config_file:
            config_file.write(json.dumps(self.valid_config_globally_not_enabled))

        self.invalid_config_missing_field_file = path.join(
            self.test_dir,
            'invalid_config_missing_field.json'
        )

        with open(self.invalid_config_missing_field_file, 'w') as config_file:
            config_file.write(json.dumps(self.invalid_config_missing_field))

    def tearDown(self):
        # remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_is_split_by_recipient_enabled_globally_enabled(self):
        globally_enabled_config = RecipientSplitConfig(
            self.valid_config_globally_enabled_file
        )

        # enabled for customer id not found in the list
        self.assertTrue(
            globally_enabled_config.is_split_by_recipient_enabled(
                'abcdefab-abcd-abcd-abcd-123456789012'
            )
        )

        # enabled for customer id found in the list
        self.assertTrue(
            globally_enabled_config.is_split_by_recipient_enabled(
                '84e61a73-5e3b-4616-8719-6098a0cb0ede'
            )
        )

    def test_is_split_by_recipient_enabled_globally_disabled(self):
        globally_disabled_config = RecipientSplitConfig(
            self.valid_config_globally_not_enabled_file
        )

        # disabled for customer id not found in the list
        self.assertFalse(
            globally_disabled_config.is_split_by_recipient_enabled(
                'abcdefab-abcd-abcd-abcd-123456789012'
            )
        )

        # enabled for customer id found in the list
        self.assertTrue(
            globally_disabled_config.is_split_by_recipient_enabled(
                '84e61a73-5e3b-4616-8719-6098a0cb0ede'
            )
        )

    def test_is_split_by_recipient_config_file_not_found(self):
        globally_disabled_config = RecipientSplitConfig('does-not-exist.json')

        self.assertFalse(globally_disabled_config.is_globally_enabled)
        self.assertEquals(globally_disabled_config.customer_ids_enabled, [])

        # enabled for customer id found in the list
        self.assertFalse(
            globally_disabled_config.is_split_by_recipient_enabled(
                '84e61a73-5e3b-4616-8719-6098a0cb0ede'
            )
        )

    def test_invalid_config_missing_field(self):
        with self.assertRaises(KeyError):
            RecipientSplitConfig(
                self.invalid_config_missing_field_file
            )

    def test_invalid_config_missing_field(self):
        with self.assertRaises(KeyError):
            RecipientSplitConfig(
                self.invalid_config_missing_field_file
            )

if __name__ == "__main__":
    unittest.main()
