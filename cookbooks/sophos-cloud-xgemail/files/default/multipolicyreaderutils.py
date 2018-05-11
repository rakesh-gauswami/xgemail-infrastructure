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

import json
import logging
import base64
from logging.handlers import SysLogHandler

#Constants
POLICY_STORAGE_PATH = '/policy-storage'
MULTI_POLICY_DOMAINS_PATH = POLICY_STORAGE_PATH + '/config/policies/domains/'
MULTI_POLICY_CONFIG_PATH  = POLICY_STORAGE_PATH + '/config/inbound-relay-control/multi-policy/'
MULTI_POLICY_CONFIG_FILE = MULTI_POLICY_CONFIG_PATH + 'global.CONFIG'

logger = logging.getLogger('multi-policy-reader-utils')
logger.setLevel(logging.INFO)
syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
syslog_handler.formatter = formatter
logger.addHandler(syslog_handler)

def get_multi_policy_enabled():
    try:
        with open(MULTI_POLICY_CONFIG_FILE) as config_file:
            config_data = json.load(config_file)
            return config_data['multi.policy.enabled'] and config_data['multi.policy.enabled'] == "true"
    except IOError:
        return False


def load_multi_policy_file(filename):
    try:
        with open(filename) as filehandle:
            return json.load(filehandle)

    except IOError:
        logger.info("File not exist or failed to read. [{0}]".format(
            filename)
        )


def build_recipient_file_path(recipient):
    try:
        user_part, domain_part = recipient.split("@")
        return MULTI_POLICY_DOMAINS_PATH + domain_part + "/" + base64.b64encode(user_part)
    except ValueError:
        logger.info("Invalid recipient address. [{0}]".format(
            recipient)
        )

def build_policy_map(recipients, policies = {}):

    policy_list = policies.copy()
    for recipient in recipients:
        file_name = build_recipient_file_path(recipient)
        if not file_name:
            return None

        customer_policy = load_multi_policy_file(file_name)
        if not customer_policy:
            return None

        if customer_policy['policyId'] not in policy_list.keys():
            policy_list[customer_policy['policyId']] = [recipient]
        else:
            recipient_list = policy_list[customer_policy['policyId']]
            recipient_list.append(recipient)

    return policy_list