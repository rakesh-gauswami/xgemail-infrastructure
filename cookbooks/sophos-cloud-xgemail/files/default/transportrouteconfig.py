#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Provides methods for accessing transport routing configuration.
# Specifically, which behavior should be employed when transport route data is missing from S3.
# There are three options:
#
# "IGNORE" - Missing data should be ignored and an "Unknown" header value should be used.
# "RETRIEVE" - Attempt to retrieve the header value from the mail PIC. Fail if this cannot be done.
# "ERROR" - Throw an error and cease processing.


import argparse
import json
import logging
from logging.handlers import SysLogHandler

IGNORE_VAL = 'IGNORE'
RETRIEVE_VAL = 'RETRIEVE'
ERROR_VAL = 'ERROR'

PERMITTED_VALUES = {
    IGNORE_VAL,
    RETRIEVE_VAL,
    ERROR_VAL
}

class TransportRouteConfig(object):

    def __init__(
        self,
        config_file_name
    ):

        self.config_file_name = config_file_name
        self.transport_config = None
        self.transport_config_read = False

        # The default value is IGNORE
        self.on_missing_transport_data = IGNORE_VAL

        self.logger = logging.getLogger('transport-route-config')
        self.logger.setLevel(logging.INFO)

        syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
        syslog_handler.formatter = logging.Formatter(
            '[%(name)s] %(process)d %(levelname)s %(message)s'
        )

        self.logger.addHandler(syslog_handler)

    def read_config(self):

        try:
            with open(self.config_file_name) as transport_config_file:
                self.transport_config = json.load(transport_config_file)

                if 'behavior_on_missing_transport_data' in self.transport_config:

                    unvalidated_config_value = self.transport_config['behavior_on_missing_transport_data']

                    # Verify that the new value is one of the permitted values
                    if unvalidated_config_value in PERMITTED_VALUES:
                        self.on_missing_transport_data = unvalidated_config_value


                self.transport_config_read = True

        except IOError as exception:
            self.logger.error(
                'Error loading transport config file {0}. Exception {1} '.format(
                    self.config_file_name,
                    exception
                )
            )

    def get_on_missing_data_setting(self):

        if not self.transport_config_read:
            self.read_config()

        return self.on_missing_transport_data


    def is_error_on_missing_data(self):

        if not self.transport_config_read:
            self.read_config()

        return self.on_missing_transport_data == ERROR_VAL

    def is_retrieve_on_missing_data(self):

        if not self.transport_config_read:
            self.read_config()

        return self.on_missing_transport_data == RETRIEVE_VAL

    def is_ignore_on_missing_data(self):

        if not self.transport_config_read:
            self.read_config()

        return self.on_missing_transport_data == IGNORE_VAL
