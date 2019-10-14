#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import json
import os

class RecipientSplitConfig:
    """
    Contains configuration that determines if messages are split by recipients

    Default configuration (if config file not found):
        - is_globally_enabled: False
        - customer_ids_enabled: []
    """
    def __init__(self, absolute_path_to_config):
        if not os.path.isfile(absolute_path_to_config):
            # use defaults if the config file doesn't exist
            self.is_globally_enabled = False
            self.customer_ids_enabled = []
        else:
            with open(absolute_path_to_config) as config_file:
                config = json.load(config_file)
                self.is_globally_enabled = config['is_globally_enabled']
                self.customer_ids_enabled = config['customer_ids_enabled']

    def is_split_by_recipient_enabled(self, customer_id):
        """
        Returns true if recipient split either globally enabled or specifically
        enabled for the provided customer_id
        """
        if self.is_globally_enabled:
            return True

        return (customer_id in self.customer_ids_enabled)

    def is_split_by_recipient_globally_enabled(self):
        """
        Returns true if recipient split either globally enabled or specifically
        enabled for the provided customer_id
        """
        return self.is_globally_enabled
