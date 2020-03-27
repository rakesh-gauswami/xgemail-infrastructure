#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2020, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Representation of a configuration for Delivery director


class DeliveryDirectorThreshold:

    def __init__(self,
                 domain_threshold=50,
                 email_threshold=10,
                 warmup_percentage=0):
        self.domain_threshold = domain_threshold
        self.email_threshold = email_threshold
        self.warmup_percentage = warmup_percentage

    def get_deliverdirector_threshold_json(self):
        return self.__dict__

    def get_domain_threshold(self):
        return self.domain_threshold

    def get_email_threshold(self):
        return self.email_threshold

    def get_warmup_percentage(self):
        return self.warmup_percentage

    def set_domain_threshold(self, domain_threshold):
        self.domain_threshold = domain_threshold

    def set_email_threshold(self, email_threshold):
        self.email_threshold = email_threshold

    def set_warmup_percentage(self, warmup_percentage):
        self.warmup_percentage = warmup_percentage