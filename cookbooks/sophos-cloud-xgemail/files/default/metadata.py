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

import re
import uuid

class Metadata:
    uuid_regex = re.compile("^\w+_UUID_\w+$", re.IGNORECASE)

    def __init__(self,
                 schema_version,
                 sender_ip,
                 sender_address,
                 accepting_server_ip,
                 queue_id,
                 date_recorded,
                 recipient_domain,
                 recipients,
                 x_sophos_email_id = None,
                 is_microservice_request=False):
        self.schema_version = schema_version
        self.sender_ip = sender_ip
        self.sender_address = sender_address
        self.accepting_server_ip = accepting_server_ip
        self.queue_id = queue_id
        self.date_recorded = date_recorded
        self.recipient_domain = recipient_domain
        self.recipients = recipients
        self.is_microservice_request = is_microservice_request
        self.x_sophos_email_id = x_sophos_email_id

    def __str__(self):
        metadata_json = self.get_metadata_json()
        return ', '.join('%s=%s' % (key, value) for (key, value) in metadata_json.iteritems())

    def get_metadata_json(self):
        return self.__dict__

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

    def get_x_sophos_emai_id(self):
        return self.x_sophos_email_id

    def set_x_sophos_emai_id(self, x_sophos_email_id):
        self.x_sophos_email_id = x_sophos_email_id

    def is_microservice_request(self):
        return self.is_microservice_request

    def set_microservice_request(self, is_microservice_request):
        self.is_microservice_request = is_microservice_request

    def add_uuid_to_queue_id(self):
        """
        Adds a UUID to the queue_id to generate a truly unique queue_id string.
        If a UUID is already part of queue_id, this method returns without adding a new UUID.
        """
        if self.uuid_regex.match(self.queue_id):
            # uuid has already been added, don't add it again
            return

        msg_uuid = str(uuid.uuid4()).replace('-','')
        self.queue_id = '{0}_UUID_{1}'.format(self.queue_id, msg_uuid)
