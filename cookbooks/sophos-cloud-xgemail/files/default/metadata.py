#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Representation of a message metadata

class Metadata:
    def __init__(self,
                 schema_version,
                 sender_ip,
                 sender_address,
                 accepting_server_ip,
                 queue_id,
                 date_recorded,
                 recipient_domain,
                 recipients):
        self.schema_version = schema_version
        self.sender_ip = sender_ip
        self.sender_address = sender_address
        self.accepting_server_ip = accepting_server_ip
        self.queue_id = queue_id
        self.date_recorded = date_recorded
        self.recipient_domain = recipient_domain
        self.recipients = recipients

    def __str__(self):
        metadata_json = self.get_metadata_json()
        return ', '.join('%s=%s' % (key, value) for (key, value) in metadata_json.iteritems())

    def get_metadata_json(self):
        return {
            'schema_version': self.schema_version,
            'sender_ip': self.sender_ip,
            'sender_address': self.sender_address,
            'accepting_server_ip': self.accepting_server_ip,
            'queue_id': self.queue_id,
            'date_recorded': self.date_recorded,
            'recipients': self.recipients
        }

    def get_schema_version(self):
        return self.schema_version

    def get_sender_address(self):
        return self.sender_address

    def get_sender_ip(self):
        return self.sender_ip

    def get_accepting_server_ip(self):
        return self.accepting_server_ip

    def get_queue_id(self):
        return self.queue_id

    def get_date_recorded(self):
        return self.date_recorded

    def get_recipient_domain(self):
        return self.recipient_domain

    def get_recipients(self):
        return self.recipients

    def set_recipients(self, recipients):
        self.recipients = recipients

    def set_queue_id(self, queue_id):
        self.queue_id = queue_id
