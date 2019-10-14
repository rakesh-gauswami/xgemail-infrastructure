#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python
#
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import sys
import logging
from logging.handlers import SysLogHandler

try:
    import mock
except ImportError:
    # Python 2.x doesn't provide the above module as part of its standard library.
    #
    # In order to run this unit test on your local machine, you need to install
    # the mock library as explained here: https://pypi.org/project/mock
    print 'mock library not installed. Skipping these unit tests.'
    sys.exit(0)

import copy
import json
from os import path
import shutil
import tempfile
import unittest
import imp

absolute_path = path.dirname(path.realpath(__file__))
INBOUND = "INBOUND"
OUTBOUND = "OUTBOUND"

# on OSX, the file /dev/log does not exist and needs to be changed to /var/run/syslog
if sys.platform.startswith('darwin'):
    with mock.patch('__main__.logging.handlers.SysLogHandler', create=True) as mocked_logging:
        mocked_logging.return_value = logging.handlers.SysLogHandler(address='/var/run/syslog')
        user_based_split_module = imp.load_source(
            'user_based_split', 
            '{0}/{1}'.format(absolute_path, 'xgemail.user.based.split.py.erb')
        )
else:
    user_based_split_module = imp.load_source(
        'user_based_split', 
        '{0}/{1}'.format(absolute_path, 'xgemail.user.based.split.py.erb')
    )

class UserBasedSplitTest(unittest.TestCase):
    config_valid = {
        'is_globally_enabled': False,
        'customer_ids_enabled': [
            '84e61a73-5e3b-4616-8719-6098a0cb0ede',
            '99e61a73-5e3b-4616-8719-6098a0cb0ede'
        ]
    }

    def setUp(self):
        # create a temporary directory
        self.test_dir = tempfile.mkdtemp()

        self.config_valid_file = path.join(
            self.test_dir,
            'config_valid.json'
        )

        with open(self.config_valid_file, 'w') as config_file:
            config_file.write(json.dumps(self.config_valid))
        user_based_split_module.SPLIT_RECIPIENT_CONFIG_FILE_INBOUND = self.config_valid_file
        user_based_split_module.SPLIT_RECIPIENT_CONFIG_FILE_OUTBOUND = self.config_valid_file

    def tearDown(self):
        # remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_validate_uuid(self):
        self.assertTrue(user_based_split_module.validate_uuid('84e61a73-5e3b-4616-8719-6098a0cb0ede'))
        self.assertTrue(user_based_split_module.validate_uuid('12345678-abcd-ef12-9999-888888888888'))

        self.assertFalse(user_based_split_module.validate_uuid('84e61a73-5e3b-4616-8719-6098a0cb0ed'))
        self.assertFalse(user_based_split_module.validate_uuid('gggg1a73-5e3b-4616-8719-6098a0cb0ede'))
        self.assertTrue(user_based_split_module.validate_uuid('84e61a735e3b461687196098a0cb0ede'))

    def test_update_global_config(self):
        updated_config = copy.deepcopy(self.config_valid)
        updated_config['is_globally_enabled'] = True

        user_based_split_module.update_global_config(True, INBOUND)

        retrieved_config = user_based_split_module.get_current_config(self.config_valid_file)

        self.assertIsNotNone(retrieved_config)
        self.assertEquals(json.dumps(retrieved_config, sort_keys=True), json.dumps(updated_config, True))

    def test_add_customer(self):
        updated_config = copy.deepcopy(self.config_valid)
        updated_config['customer_ids_enabled'].append('ffffffff-5e3b-4616-8719-6098a0cb0ede')

        user_based_split_module.add_customer('ffffffff-5e3b-4616-8719-6098a0cb0ede', INBOUND)

        retrieved_config = user_based_split_module.get_current_config(self.config_valid_file)

        self.assertIsNotNone(retrieved_config)
        self.assertTrue(len(updated_config['customer_ids_enabled']) == 3)
        self.assertEquals(json.dumps(retrieved_config, sort_keys=True), json.dumps(updated_config, True))

    def test_remove_customer(self):
        updated_config = copy.deepcopy(self.config_valid)
        updated_config['customer_ids_enabled'].remove('99e61a73-5e3b-4616-8719-6098a0cb0ede')

        user_based_split_module.remove_customer('99e61a73-5e3b-4616-8719-6098a0cb0ede', INBOUND)

        retrieved_config = user_based_split_module.get_current_config(self.config_valid_file)

        self.assertIsNotNone(retrieved_config)
        self.assertTrue(len(updated_config['customer_ids_enabled']) == 1)
        self.assertEquals(json.dumps(retrieved_config, sort_keys=True), json.dumps(updated_config, True))

    def test_add_customer_outbound(self):
        updated_config = copy.deepcopy(self.config_valid)
        updated_config['customer_ids_enabled'].append('ffffffff-5e3b-4616-8719-6098a0cb0ede')

        user_based_split_module.add_customer('ffffffff-5e3b-4616-8719-6098a0cb0ede', OUTBOUND)

        retrieved_config = user_based_split_module.get_current_config(self.config_valid_file)

        self.assertIsNotNone(retrieved_config)
        self.assertTrue(len(updated_config['customer_ids_enabled']) == 3)
        self.assertEquals(json.dumps(retrieved_config, sort_keys=True), json.dumps(updated_config, True))

    def test_remove_customer_outbound(self):
        updated_config = copy.deepcopy(self.config_valid)
        updated_config['customer_ids_enabled'].remove('99e61a73-5e3b-4616-8719-6098a0cb0ede')

        user_based_split_module.remove_customer('99e61a73-5e3b-4616-8719-6098a0cb0ede', OUTBOUND)

        retrieved_config = user_based_split_module.get_current_config(self.config_valid_file)

        self.assertIsNotNone(retrieved_config)
        self.assertTrue(len(updated_config['customer_ids_enabled']) == 1)
        self.assertEquals(json.dumps(retrieved_config, sort_keys=True), json.dumps(updated_config, True))

    def test_get_current_config(self):
        retrieved_config = user_based_split_module.get_current_config(self.config_valid_file)

        self.assertIsNotNone(retrieved_config)
        self.assertEquals(json.dumps(retrieved_config, sort_keys=True), json.dumps(self.config_valid, True))

    def test_write_config(self):
        updated_config = copy.deepcopy(self.config_valid)
        updated_config['is_globally_enabled'] = True
        updated_config['customer_ids_enabled'] = ['ffffffff-5e3b-4616-8719-6098a0cb0ede']

        user_based_split_module.write_config(updated_config, self.config_valid_file)

        retrieved_config = user_based_split_module.get_current_config(self.config_valid_file)

        self.assertIsNotNone(retrieved_config)
        self.assertEquals(json.dumps(retrieved_config, sort_keys=True), json.dumps(updated_config, True))

if __name__ == "__main__":
    unittest.main()
