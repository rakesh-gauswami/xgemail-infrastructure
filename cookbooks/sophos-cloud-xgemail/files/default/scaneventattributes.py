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
# Representation of message attributes for scan event

class ScanEventAttributes:
    def __init__(self,
                 service,
                 event,
                 version):
        self.service = service
        self.event = event
        self.version = version

    def __str__(self):
        scan_event_attributes_json = self.get_scan_event_attributes_json()
        return ', '.join('%s=%s' % (key, value) for (key, value) in scan_event_attributes_json.iteritems())

    def get_scan_event_attributes_json(self):
        return self.__dict__

    def get_service(self):
        return self.service

    def get_event(self):
        return self.event

    def get_version(self):
        return self.version
