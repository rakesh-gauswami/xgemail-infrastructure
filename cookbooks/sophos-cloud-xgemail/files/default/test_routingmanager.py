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


import unittest
import shutil
import argparse
import json
import os
from routingmanager import RoutingManager

class RoutingManagerTest(unittest.TestCase):

    def setUp(self):

        self.test_data_dir = 'routing-manager-test'
        self.manager_name = 'routing-name'
        self.test_config_path = '%s/config/routing/%s/' % (self.test_data_dir, self.manager_name)
        self.routing_manager = self.create_routing_manager()

    def tearDown(self):
        if os.path.exists(self.test_data_dir):
            shutil.rmtree(self.test_data_dir)


    def create_routing_manager(self):

        ret_val = None;

        if sys.platform.startswith('darwin'):
            with mock.patch('__main__.logging.handlers.SysLogHandler', create=True) as mocked_logging:
                mocked_logging.return_value = logging.handlers.SysLogHandler(address='/var/run/syslog')
                ret_val = RoutingManager(
                    self.test_data_dir,
                    self.manager_name
                )
        else:
            ret_val = RoutingManager(
                self.test_data_dir,
                self.manager_name
            )

        return ret_val

    @mock.patch('random.random')
    def test_perform_routing_with_customer_file(self, mock_random):

        customer_file_name = self.test_config_path + '/customer-id-routing-000.ROUTING'

        if not os.path.exists(self.test_config_path):
            os.makedirs(self.test_config_path)

        open(customer_file_name, 'a').close()

        self.assertTrue(self.routing_manager.perform_routing('customer-id-routing-000'))

        mock_random.assert_not_called()


    @mock.patch('random.random')
    def test_perform_routing_without_customer_file_do_routing(self, mock_random):
        self.manually_write_routing_config_with_percentage(0.33)
        mock_random.return_value =  0.55
        self.assertTrue(self.routing_manager.perform_routing('customer-missing'))


    @mock.patch('random.random')
    def test_perform_routing_without_customer_file_no_routing(self, mock_random):
        self.manually_write_routing_config_with_percentage(0.33)
        mock_random.return_value = 0.11
        self.assertFalse(self.routing_manager.perform_routing('customer-missing'))

    @mock.patch('random.random')
    @mock.patch('__builtin__.open')
    def test_perform_routing_without_customer_or_config_file(self, mock_open, mock_random):
        mock_open.side_effect = IOError('load error')
        self.assertFalse(self.routing_manager.perform_routing('customer-io-error'))
        mock_random.assert_not_called()

    @mock.patch('os.path.isfile')
    def test_perform_routing_with_none_customer_id(self, mock_is_file):
        self.routing_manager.perform_routing(None)
        mock_is_file.assert_not_called()

    def test_verify_config_dir(self):

        if os.path.exists(self.test_data_dir):
            shutil.rmtree(self.test_data_dir)

        self.assertFalse(os.path.exists(self.test_data_dir))
        self.routing_manager.verify_config_dir()
        self.assertTrue(os.path.exists(self.test_data_dir))


    def test_get_routing_percent_file_exists(self):

        self.manually_write_routing_config_with_percentage(0.67)

        self.assertEqual(self.routing_manager.get_routing_percent(), 0.67)

        
    def test_get_routing_percent_file_missing(self):
        if os.path.exists(self.test_data_dir):
            shutil.rmtree(self.test_data_dir)

        self.assertEqual(self.routing_manager.get_routing_percent(), 0.0)


    def test_set_routing_percent(self):
        self.routing_manager.set_routing_percent(0.43)

        routing_file_name = self.test_config_path + '/routing-name-routing.CONFIG'

        with open(routing_file_name) as routing_file:
            config_data = json.load(routing_file)
            self.assertEqual(float(config_data['percent.traffic.to.route']), 0.43)


    def test_set_customer(self):
        customer_file_name = self.test_config_path + '/customer-id-set-000.ROUTING'
        self.assertFalse(os.path.isfile(customer_file_name))
        self.routing_manager.set_customer('customer-id-set-000')
        self.assertTrue(os.path.isfile(customer_file_name))


    def test_remove_customer(self):
        customer_file_name = self.test_config_path + '/customer-id-remove-000.ROUTING'

        if not os.path.exists(self.test_config_path):
            os.makedirs(self.test_config_path)

        open(customer_file_name, 'a').close()

        self.assertTrue(os.path.isfile(customer_file_name))
        self.routing_manager.remove_customer('customer-id-remove-000')
        self.assertFalse(os.path.isfile(customer_file_name))


    def manually_write_routing_config_with_percentage(self, new_percent):
        config_data = {'percent.traffic.to.route': new_percent}

        routing_file_name = self.test_config_path + '/routing-name-routing.CONFIG'

        if not os.path.exists(self.test_config_path):
            os.makedirs(self.test_config_path)

        with open(routing_file_name, 'w') as routing_file:
            json.dump(config_data, routing_file)


    def test_valid_float(self):

        invalid_values = [1.1, 1.11, 2.0, 10.1, -0.1, -1.1]
        valid_values = [0.0, 1.0, 0.01, 0.1, 0.5, 0.99]

        for value in invalid_values:
            self.assertRaises(argparse.ArgumentTypeError, self.routing_manager.valid_float, value)

        for value in valid_values:
            self.assertEqual(value, self.routing_manager.valid_float(value))

if __name__ == "__main__":
    unittest.main()