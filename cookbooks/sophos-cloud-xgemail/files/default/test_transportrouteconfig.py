#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python
#
# Copyright 2019, Sophos Limited. All rights reserved.
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
from transportrouteconfig import TransportRouteConfig

class TransportRouteConfigTest(unittest.TestCase):

    def create_config(self):

        ret_val = None

        if sys.platform.startswith('darwin'):
            with mock.patch('__main__.logging.handlers.SysLogHandler', create=True) as mocked_logging:
                mocked_logging.return_value = logging.handlers.SysLogHandler(address='/var/run/syslog')
                ret_val = TransportRouteConfig('path/to/config/transport-config.json')

        else:
            ret_val = TransportRouteConfig('path/to/config/transport-config.json')

        return ret_val


    @mock.patch('__builtin__.open')
    def test_with_error_config_setting(self, mock_open):

        mock_open.side_effect = [
            mock.mock_open(read_data = '{"behavior_on_missing_transport_data": "ERROR"}').return_value
        ]

        transport_config = self.create_config()

        self.assertTrue(transport_config.is_error_on_missing_data())
        self.assertFalse(transport_config.is_retrieve_on_missing_data())
        self.assertFalse(transport_config.is_ignore_on_missing_data())


    @mock.patch('__builtin__.open')
    def test_get_on_missing_data_with_retrieve(self, mock_open):

        mock_open.side_effect = [
            mock.mock_open(read_data = '{"behavior_on_missing_transport_data": "RETRIEVE"}').return_value
        ]

        transport_config = self.create_config()

        self.assertEquals(transport_config.get_on_missing_data_setting(), 'RETRIEVE')


    @mock.patch('__builtin__.open')
    def test_get_on_missing_data_with_error(self, mock_open):

        mock_open.side_effect = [
            mock.mock_open(read_data = '{"behavior_on_missing_transport_data": "ERROR"}').return_value
        ]

        transport_config = self.create_config()

        self.assertEquals(transport_config.get_on_missing_data_setting(), 'ERROR')

    @mock.patch('__builtin__.open')
    def test_get_on_missing_data_with_ignore(self, mock_open):

        mock_open.side_effect = [
            mock.mock_open(read_data = '{"behavior_on_missing_transport_data": "IGNORE"}').return_value
        ]

        transport_config = self.create_config()

        self.assertEquals(transport_config.get_on_missing_data_setting(), 'IGNORE')


    @mock.patch('__builtin__.open')
    def test_get_on_missing_data_with_bad_case(self, mock_open):

        mock_open.side_effect = [
            mock.mock_open(read_data = '{"behavior_on_missing_transport_data": "error"}').return_value
        ]

        transport_config = self.create_config()

        self.assertEquals(transport_config.get_on_missing_data_setting(), 'IGNORE')


    @mock.patch('__builtin__.open')
    def test_with_retrieve_config_setting(self, mock_open):

        mock_open.side_effect = [
            mock.mock_open(read_data = '{"behavior_on_missing_transport_data": "RETRIEVE"}').return_value
        ]

        transport_config = self.create_config()

        self.assertFalse(transport_config.is_error_on_missing_data())
        self.assertTrue(transport_config.is_retrieve_on_missing_data())
        self.assertFalse(transport_config.is_ignore_on_missing_data())


    @mock.patch('__builtin__.open')
    def test_with_ignore_config_setting(self, mock_open):

        mock_open.side_effect = [
            mock.mock_open(read_data = '{"behavior_on_missing_transport_data": "IGNORE"}').return_value
        ]

        transport_config = self.create_config()

        self.assertFalse(transport_config.is_error_on_missing_data())
        self.assertFalse(transport_config.is_retrieve_on_missing_data())
        self.assertTrue(transport_config.is_ignore_on_missing_data())


    @mock.patch('__builtin__.open')
    def test_with_incorrect_attributes(self, mock_open):

        mock_open.side_effect = [
            mock.mock_open(read_data = '{"something_else": "FOO"}').return_value
        ]

        transport_config = self.create_config()

        self.assertFalse(transport_config.is_error_on_missing_data())
        self.assertFalse(transport_config.is_retrieve_on_missing_data())
        self.assertTrue(transport_config.is_ignore_on_missing_data())


    @mock.patch('__builtin__.open')
    def test_with_load_error(self, mock_open):
        mock_open.side_effect = IOError('load error')

        transport_config = self.create_config()

        self.assertFalse(transport_config.is_error_on_missing_data())
        self.assertFalse(transport_config.is_retrieve_on_missing_data())
        self.assertTrue(transport_config.is_ignore_on_missing_data())


if __name__ == "__main__":
    unittest.main()





