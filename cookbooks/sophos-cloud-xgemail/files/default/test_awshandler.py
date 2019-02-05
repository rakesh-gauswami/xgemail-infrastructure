#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python
#
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import logging
import sys
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

import unittest
import shutil
import os
from awshandler import AwsHandler

class AwsHandlerTest(unittest.TestCase):

    def setUp(self):
        self.aws_region = 'us-east-1'
        self.test_data_dir = 'aws-handler-test'
        self.test_config_path = '%s/config/awshandler/%s/' % (self.test_data_dir, self.aws_region)
        self.awshandler = self.create_awshandler()

    def tearDown(self):
        if os.path.exists(self.test_data_dir):
            shutil.rmtree(self.test_data_dir)

    @mock.patch('awshandler.boto3.client')
    def create_awshandler(self, boto3_client):
        if sys.platform.startswith('darwin'):
            with mock.patch('__main__.logging.handlers.SysLogHandler', create=True) as mocked_logging:
                mocked_logging.return_value = logging.handlers.SysLogHandler(address='/var/run/syslog')
                return AwsHandler(
                    self.aws_region
                )
        else:
            return AwsHandler(
                self.aws_region
            )

    def test_publish_to_sns_topic(self):
        topic_arn = "arn:aws:sns:us-east-1:123456789012:xgemail-scan-events-SNS"
        message_body = "Testing"
        message_attributes = {
            "service" : {
                "DataType" : "String",
                "StringValue": "test-service"
            }
        }
        response = self.awshandler.publish_to_sns_topic(topic_arn, message_body, message_attributes)
        self.assertIsNotNone(response)
        self.assertEqual(self.awshandler.sns_client.publish.call_count, 1)
        self.assertEqual(self.awshandler.sqs_client.send_message.call_count, 0)

if __name__ == "__main__":
    unittest.main()