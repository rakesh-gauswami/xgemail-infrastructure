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
# Representation of a message attributes

class MessageAttributes:
    def __init__(self,
                 service,
                 event,
                 version):
        self.service = service
        self.event = event
        self.version = version

    def __str__(self):
        message_attributes_json = self.get_message_attributes_json()
        return ', '.join('%s=%s' % (key, value) for (key, value) in message_attributes_json.iteritems())

    def get_message_attributes_json(self):
        return self.__dict__

    def get_service(self):
        return self.service

    def get_event(self):
        return self.event

    def get_version(self):
        return self.version
