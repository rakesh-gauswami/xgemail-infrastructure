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
# Enumeration of the possible ServerTypes

from enum import Enum


class ServerType(Enum):
    INTERNET_SUBMIT = 'internet-submit'
    INTERNET_DELIVERY = 'internet-delivery'
    INTERNET_XDELIVERY = 'internet-xdelivery'
    CUSTOMER_SUBMIT = 'customer-submit'
    CUSTOMER_DELIVERY = 'customer-delivery'
    CUSTOMER_XDELIVERY = 'customer-xdelivery'

    @staticmethod
    def from_string(string):
        string = string.lower()
        for server_type in ServerType:
            if server_type.value.lower() == string:
                return server_type
        if string == 'delivery':
            return ServerType.CUSTOMER_DELIVERY
        elif string == 'submit':
            return ServerType.INTERNET_SUBMIT
        else:
            raise ValueError('Cannot create ServerType enum from input string <{}>'.format(string))


