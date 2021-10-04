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

import json
from os import path
import shutil
import tempfile
import unittest
import awshandler

from mock import call
from recipientsplitconfig import RecipientSplitConfig



# on OSX, the file /dev/log does not exist and needs to be changed to /var/run/syslog
if sys.platform.startswith('darwin'):
    with mock.patch('__main__.logging.handlers.SysLogHandler', create=True) as mocked_logging:
        mocked_logging.return_value = logging.handlers.SysLogHandler(address='/var/run/syslog')
        import multipolicyreaderutils
else:
    import multipolicyreaderutils

class MultiPolicyReaderUtilsTest(unittest.TestCase):
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

    mock_policy = {
        "customerId":"76656a08-c17b-47d6-aafd-ef8fc7c250a0",
        "userId":"5908cc03a2a94d0f94a472df",
        "policyId":"e8cb39e49c083a96f7fad75ee60e7369249ec83c71c09951c1825a03b2cb09f9",
        "endpointId":"2acedd58-a9cb-4a82-8696-e5546ed52c70",
        "schema_version":20170825
    }

    mock_policy_customer_enabled = {
        "customerId":"84e61a73-5e3b-4616-8719-6098a0cb0ede",
        "userId":"5908cc03a2a94d0f94a472df",
        "policyId":"e8cb39e49c083a96f7fad75ee60e7369249ec83c71c09951c1825a03b2cb09f9",
        "endpointId":"2acedd58-a9cb-4a82-8696-e5546ed52c70",
        "schema_version":20170825
    }

    mock_policy_invalid = {
        "userId":"5908cc03a2a94d0f94a472df",
        "policyId":"e8cb39e49c083a96f7fad75ee60e7369249ec83c71c09951c1825a03b2cb09f9",
        "endpointId":"2acedd58-a9cb-4a82-8696-e5546ed52c70",
        "schema_version":20170825
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
            'valid_config_globally_not_enabled.json'
        )

        with open(self.valid_config_globally_not_enabled_file, 'w') as config_file:
            config_file.write(json.dumps(self.valid_config_globally_not_enabled))

    def tearDown(self):
        # remove the directory after the test
        shutil.rmtree(self.test_dir)

    @mock.patch('multipolicyreaderutils.read_policy')
    def test_split_by_recipient_only_one_recipient(self, mock_read_policy):
        globally_enabled_config = RecipientSplitConfig(
            self.valid_config_globally_enabled_file
        )

        do_split_by_recipient = multipolicyreaderutils.split_by_recipient(
            globally_enabled_config,
            ['recipient-a@domain.com'],
            'eu-central-1',
            'bucket-name',
            True
        )

        self.assertFalse(do_split_by_recipient)
        mock_read_policy.assert_not_called()

    @mock.patch('multipolicyreaderutils.read_policy')
    def test_split_by_recipient_invalid_config(self, mock_read_policy):
        mock_read_policy.return_value = self.mock_policy_invalid

        globally_enabled_config = RecipientSplitConfig(
            self.valid_config_globally_enabled_file
        )

        do_split_by_recipient = multipolicyreaderutils.split_by_recipient(
            globally_enabled_config,
            ['recipient-a@domain.com', 'recipient-b@domain.com'],
            'eu-central-1',
            'bucket-name',
            True
        )

        self.assertFalse(do_split_by_recipient)
        mock_read_policy.assert_called_with(
            'recipient-a@domain.com',
            'eu-central-1',
            'bucket-name',
            True
        )

    @mock.patch('multipolicyreaderutils.read_policy')
    def test_split_by_recipient_globally_enabled(self, mock_read_policy):
        mock_read_policy.return_value = self.mock_policy

        globally_enabled_config = RecipientSplitConfig(
            self.valid_config_globally_enabled_file
        )

        do_split_by_recipient = multipolicyreaderutils.split_by_recipient(
            globally_enabled_config,
            ['recipient-a@domain.com', 'recipient-b@domain.com'],
            'eu-central-1',
            'bucket-name',
            True
        )

        self.assertTrue(do_split_by_recipient)
        mock_read_policy.assert_called_with(
            'recipient-a@domain.com',
            'eu-central-1',
            'bucket-name',
            True
        )

    @mock.patch('multipolicyreaderutils.read_policy')
    def test_split_by_recipient_not_globally_enabled_customer_not_enabled(self, mock_read_policy):
        mock_read_policy.return_value = self.mock_policy

        globally_not_enabled_config = RecipientSplitConfig(
            self.valid_config_globally_not_enabled_file
        )

        do_split_by_recipient = multipolicyreaderutils.split_by_recipient(
            globally_not_enabled_config,
            ['recipient-a@domain.com', 'recipient-b@domain.com'],
            'eu-central-1',
            'bucket-name',
            True
        )

        self.assertFalse(do_split_by_recipient)
        mock_read_policy.assert_called_with(
            'recipient-a@domain.com',
            'eu-central-1',
            'bucket-name',
            True
        )

    @mock.patch('multipolicyreaderutils.read_policy')
    def test_split_by_recipient_not_globally_enabled_customer_enabled(self, mock_read_policy):
        mock_read_policy.return_value = self.mock_policy_customer_enabled

        globally_not_enabled_config = RecipientSplitConfig(
            self.valid_config_globally_not_enabled_file
        )

        do_split_by_recipient = multipolicyreaderutils.split_by_recipient(
            globally_not_enabled_config,
            ['recipient-a@domain.com', 'recipient-b@domain.com'],
            'eu-central-1',
            'bucket-name',
            True
        )

        self.assertTrue(do_split_by_recipient)
        mock_read_policy.assert_called_with(
            'recipient-a@domain.com',
            'eu-central-1',
            'bucket-name',
            True
        )

    def test_retrieve_customer_id(self):
        self.assertEquals(
            multipolicyreaderutils.retrieve_customer_id(self.mock_policy),
            "76656a08-c17b-47d6-aafd-ef8fc7c250a0"
        )

    @mock.patch.object(awshandler.AwsHandler, 's3_key_exists')
    def test_policy_file_exists_in_S3_file_missing(self, mock_s3_key_exists):

        mock_s3_key_exists.return_value = False

        self.assertFalse(
            multipolicyreaderutils.policy_file_exists_in_S3(
                'someone@somewhere.com',
                'eu-west-1',
                'policy-bucket'
            )
        )

        calls = [
            call('policy-bucket', 'policies/domains/ba0f/somewhere.com/c29tZW9uZQ=='),
            call('policy-bucket', 'config/policies/domains/somewhere.com/c29tZW9uZQ==')
        ]
        
        mock_s3_key_exists.assert_has_calls(
             calls
        )


    @mock.patch.object(awshandler.AwsHandler, 's3_key_exists')
    def test_policy_file_exists_in_S3_file_present(self, mock_s3_key_exists):

        mock_s3_key_exists.side_effect =  [ False, True]

        self.assertTrue(
            multipolicyreaderutils.policy_file_exists_in_S3(
                'someone@somewhere.com',
                'eu-west-1',
                'policy-bucket'
            )
        )

        calls = [
            call('policy-bucket', 'policies/domains/ba0f/somewhere.com/c29tZW9uZQ=='),
            call('policy-bucket', 'config/policies/domains/somewhere.com/c29tZW9uZQ==')
        ]
        
        mock_s3_key_exists.assert_has_calls(
             calls
        )

    @mock.patch.object(awshandler.AwsHandler, 's3_key_exists')
    def test_policy_file_exists_in_S3_with_exception(self, mock_s3_key_exists):

        mock_s3_key_exists.side_effect = IOError('load error')

        self.assertFalse(
            multipolicyreaderutils.policy_file_exists_in_S3(
                'someone@somewhere.com',
                'eu-west-1',
                'policy-bucket'
            )
        )

        calls = [
            call('policy-bucket', 'policies/domains/ba0f/somewhere.com/c29tZW9uZQ=='),
            call('policy-bucket', 'config/policies/domains/somewhere.com/c29tZW9uZQ==')
        ]
        
        mock_s3_key_exists.assert_has_calls(
             calls
        )


if __name__ == "__main__":
    unittest.main()