#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Xgemail diskutils utility.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import randomutils
import json

ROUTING_CONFIG_PATH = '/policy-storage/config/routing/'

INTERNET_SUBMIT_ROUTING_CONFIG_FILE = 'internet-submit-routing.CONFIG'
CUSTOMER_SUBMIT_ROUTING_CONFIG_FILE = 'customer-submit-routing.CONFIG'

def route_to_microservice(submit_type, customer_id):

    # TODO: First lookup the customer id specific file

    if 'INTERNET' == submit_type:
        config_file = ROUTING_CONFIG_PATH + INTERNET_SUBMIT_ROUTING_CONFIG_FILE
    elif 'CUSTOMER' == submit_type:
        config_file = ROUTING_CONFIG_PATH + CUSTOMER_SUBMIT_ROUTING_CONFIG_FILE

    try:
        with open(config_file) as routing_config_file:
            routing_config = json.load(routing_config_file)

            routing_percentage = routing_config['percent.traffic.to.microservice']

    except IOError:
        return False

    (result, chance) = randomutils.roll_the_dice(routing_percentage)

    return result


