#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Provides an abstract mechanism making a decision as to whether or not traffic should be to a default destination,
# or an alternate destination. This manager does not know exactly what/where each destination is, it's purely here to
# assist with the decision making process.
#
# A new RoutingManager should be configured as follows:
#
#   my_routing_manager = RoutingManager(
#       data_storage_directory,
#       manager_name
#   )
#
#   Where:
#    - data_storage_directory: the local path to the directory where configuration files will be kept for this manager
#    - manager_name: the unique name for your manager
#

import json
import argparse
import os
import random
import logging
from logging.handlers import SysLogHandler

class RoutingManager(object):
    def __init__(
        self,
        root_storage_path,
        manager_name
    ):

        self.root_storage_path = root_storage_path
        self.routing_config_path = '%s/config/routing/%s/' % (self.root_storage_path, manager_name)
        self.routing_config_file_name = '%s%s-routing.CONFIG' % (self.routing_config_path, manager_name)
        self.manager_name = manager_name

        self.logger = logging.getLogger('routing-manager-' + self.manager_name)
        self.logger.setLevel(logging.INFO)

        syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
        syslog_handler.formatter = logging.Formatter(
            '[%(name)s] %(process)d %(levelname)s %(message)s'
        )

        self.logger.addHandler(syslog_handler)

    def __str__(self):
        return 'RoutingManager: name: <%s>, root_storage_path: <%s>, routing_config_path: <%s>, routing_config_file_name: <%s>' % (
            self.manager_name,
            self.root_storage_path,
            self.routing_config_path,
            self.routing_config_file_name
        )

    def perform_routing(self, customer_id):

        """
        Returns true if alternate routing should be performed.

        First, a specific customer configuration will be searched for. If found, result is True.

        If no specific customer configuration is found, we revert to a random routing calculation
        based on the preconfigured routing percentage. If no routing percentage has been
        configured, then the result is false
        """

        if customer_id is not None:
            customer_file_name = self.routing_config_path + customer_id + '.ROUTING'
            if os.path.isfile(customer_file_name):
                return True


        config_file = self.routing_config_file_name

        try:
            with open(config_file) as routing_config_file:
                routing_config = json.load(routing_config_file)

                routing_percentage = routing_config['percent.traffic.to.route']

        except IOError:
            return False

        chance = random.random()

        if routing_percentage <= chance:
            return True
        else:
            return False

    def verify_config_dir(self):

        """
        Verifies that the config directory for this manager exists. If it doesn't
        it will be created.
        """
        config_dir = os.path.dirname(self.routing_config_path)
        if not os.path.exists(config_dir):
            os.makedirs(config_dir)

    def get_routing_percent(self):

        """
        Get the currently configured routing percentage as a float value
        """

        try:
            with open(self.routing_config_file_name) as config_file:
                config_data = json.load(config_file)
                return float(config_data['percent.traffic.to.route'])
        except IOError as e:
            return 0.0


    def set_routing_percent(self, new_percent):

        """
        Sets the routing percentage to the provided new_percent
        """
        self.verify_config_dir()
        self.valid_float(new_percent)

        config_data = {'percent.traffic.to.route': new_percent}

        temp_file = self.routing_config_file_name + '.tmp'

        with open(temp_file, 'w') as config_file:
            json.dump(config_data, config_file)

        os.rename(temp_file, self.routing_config_file_name)

        self.logger.info('Set routing percent to {0}'.format(new_percent))


    def set_customer(self, customer_id):

        """
        Sets the customer with the given customer_id to have all their traffic alternatively routed
        """

        self.verify_config_dir()
        file_name = self.routing_config_path + customer_id + '.ROUTING'
        open(file_name, 'a').close()

        self.logger.info('Added customer <{0}> to internet submit microservice routing'.format(customer_id))

    def remove_customer(self, customer_id):

        """
         Sets the customer with the given customer_id to no longer have all their traffic alternatively routed
        """

        file_location = self.routing_config_path + customer_id + '.ROUTING'
        if not os.path.exists(file_location):
            self.logger.info('Cannot find: {0}'.format(file_location))
        else:
            os.remove(file_location)
            self.logger.info('Removed customer <{0}> from microservice routing'.format(customer_id))


    def valid_float(self, possible_float):

        """
        Validates that the given possible float value is between the range 0.00 and 1.00.
        """
        float_value = float(possible_float)
        if float_value < 0.00 or float_value > 1.00:
            raise argparse.ArgumentTypeError("%r not in range [0.00, 1.00]" % (float_value,))
        return float_value


