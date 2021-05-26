#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Xgemail Metadata class.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import json
import re
import unittest
from metadata import Metadata

class MetadataTest(unittest.TestCase):
    uuid_regex = re.compile("^\w+_uuid_\w+$", re.IGNORECASE)

    def setUp(self):
        # Create a temporary directory
        self.metadata = Metadata(
            '20181019',
            '1.2.3.4',
            'sender@address.com',
            '9.8.7.6',
            '42c6b66mZYz1V',
            '2018-10-19T13:37:00Z',
            'r-domain.com',
            ['a@r-domain.com', 'b@r-domain.com', 'c@r-domain.com'],
            'e6592dab-ae0e-466c-86b1-c891eda752d8'
        )

    def test_add_uuid_to_queue_id(self):
        self.assertFalse(self.uuid_regex.match(self.metadata.get_queue_id()))
        self.assertEquals(self.metadata.get_queue_id(), '42c6b66mZYz1V')

        self.metadata.add_uuid_to_queue_id()
        self.assertTrue(self.uuid_regex.match(self.metadata.get_queue_id()))

        updated_queue_id = self.metadata.get_queue_id()

        # verify that add_uuid_to_queue_id is idempotent
        self.metadata.add_uuid_to_queue_id()
        self.assertEquals(updated_queue_id, self.metadata.get_queue_id())
        self.assertTrue(self.uuid_regex.match(self.metadata.get_queue_id()))

    def test_get_metadata_json(self):
        expected_json = {
            "accepting_server_ip": "9.8.7.6", 
            "recipients": ["a@r-domain.com", "b@r-domain.com", "c@r-domain.com"],
            "date_recorded": "2018-10-19T13:37:00Z", 
            "schema_version": "20181019", 
            "sender_address": "sender@address.com", 
            "recipient_domain": "r-domain.com", 
            "queue_id": "42c6b66mZYz1V", 
            "sender_ip": "1.2.3.4",
            "x_sophos_email_id":"e6592dab-ae0e-466c-86b1-c891eda752d8",
            "is_microservice_request": False,
            "email_product_type": "GATEWAY"
        }
        self.assertEquals(
            json.dumps(self.metadata.get_metadata_json(), sort_keys=True), 
            json.dumps(expected_json, sort_keys=True)
        )

    def test_empty_x_sophos_email_id(self):
        metadata = Metadata(
            '20181019',
            '1.2.3.4',
            'sender@address.com',
            '9.8.7.6',
            '42c6b66mZYz1V',
            '2018-10-19T13:37:00Z',
            'r-domain.com',
            ['a@r-domain.com', 'b@r-domain.com', 'c@r-domain.com']
        )
        expected_json = {
            "accepting_server_ip": "9.8.7.6",
            "recipients": ["a@r-domain.com", "b@r-domain.com", "c@r-domain.com"],
            "date_recorded": "2018-10-19T13:37:00Z",
            "schema_version": "20181019",
            "sender_address": "sender@address.com",
            "recipient_domain": "r-domain.com",
            "queue_id": "42c6b66mZYz1V",
            "sender_ip": "1.2.3.4",
            "x_sophos_email_id": None,
            "is_microservice_request": False,
            "email_product_type": "GATEWAY"
        }
        self.assertEquals(
            json.dumps(metadata.get_metadata_json(), sort_keys=True),
            json.dumps(expected_json, sort_keys=True)
        )

if __name__ == "__main__":
    unittest.main()
