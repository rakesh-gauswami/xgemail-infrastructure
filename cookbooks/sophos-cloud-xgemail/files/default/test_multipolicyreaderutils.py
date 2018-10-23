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
from unittest.mock import create_autospec

from recipientsplitconfig import RecipientSplitConfig

class MultiPolicyReaderUtilsTest(unittest.TestCase):
    valid_config_globally_enabled = {
        'is_globally_enabled': True,
        'customer_ids_enabled': [
            '84e61a73-5e3b-4616-8719-6098a0cb0ede',
            '84e61a73-5e3b-4616-8719-6098a0cb0ede'
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

    def tearDown(self):
        # remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_split_by_recipient(self):
        globally_enabled_config = RecipientSplitConfig(
            self.valid_config_globally_enabled_file
        )

        mock_read_policy = create_autospec(read_policy, return_value={'customerId': '5'})

        split_by_recipient(
            globally_enabled_config,
            ['recipient-a@domain.com', 'recipient-b@domain.com'],
            'eu-central-1',
            'bucket-name',
            True
        )

        mock_read_policy.assert_called()

if __name__ == "__main__":
    unittest.main()
