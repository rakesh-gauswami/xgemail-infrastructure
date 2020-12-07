#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python
"""
Unit tests for the Xgemail Helper class.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import json
import re
import unittest
import messagehistory
import tempfile
import sys
import io
from sqsmessage import SqsMessage


class MessageHistoryTest(unittest.TestCase):

    def parse_sqs_message(self, msg, receipt):
        msg_as_json = json.loads(msg)
        return SqsMessage(msg_as_json["schema_version"],
                          msg_as_json["message_path"],
                          msg_as_json["accepting_server_ip"],
                          msg_as_json["queue_id"],
                          msg_as_json["akm_key"],
                          msg_as_json["nonce"],
                          msg_as_json["message_key"],
                          msg_as_json["submit_message_type"],
                          receipt,
                          None,
                          msg_as_json['message_context'] if 'message_context' in msg_as_json else None)

    def test_can_generate_mh_event_no_message_context(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\" }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        self.assertEqual(
            messagehistory.can_generate_mh_event(sqs_message), False)

    def test_can_generate_mh_event_empty_message_context(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\":  { } }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        self.assertEqual(
            messagehistory.can_generate_mh_event(sqs_message), False)

    def test_can_generate_mh_event_empty_mh_mail_info(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\":  { \"mh_mail_info\" : {} } }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        self.assertEqual(
            messagehistory.can_generate_mh_event(sqs_message), False)

    def test_can_generate_mh_event_true(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\":  { \"mh_mail_info\" : { \"generate_mh_events\" : true} } }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        self.assertEqual(
            messagehistory.can_generate_mh_event(sqs_message), True)

    def test_can_generate_mh_event_false(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\":  { \"mh_mail_info\" : { \"generate_mh_events\" : false} } }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        self.assertEqual(
            messagehistory.can_generate_mh_event(sqs_message), False)

    def test_write_mh_mail_info(self):
        raw_sqs_message = "{ \"submit_message_type\": \"INTERNET\", \"reindex\": false, \"message_path_type\": \"NORMAL\", \"mailboxes\": [ \"user1@o365.qa1.sasubr.com\" ], \"akm_key\": \"not_supported\", \"event\": \"QUEUED_FOR_DELIVERY\", \"schema_version\": 20170224, \"message_context\": { \"module_scan_results\": { \"HRU\": { \"scan_result\": \"CLEAN\", \"early_out\": false, \"persist\": true }, \"SAVI\": { \"scan_result\": \"CLEAN\", \"early_out\": false, \"persist\": true } }, \"message_auth_results\": { \"spf_result\": \"HARDFAIL\", \"dkim_result\": \"NONE\", \"authentication_results\": [ \"mx-01-eu-central-1.qa.hydra.sophos.com\", \"spf=hardfail smtp.mailfrom=admin@sasubr.com\", \"dkim=none\" ] }, \"mh_mail_info\": { \"schema_version\": 20201026, \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"mailbox_id\": \"5f50ccbb5667b70dedc25b88\", \"mailbox_address\": \"recipient1@example.com\", \"queue_id\": \"7574A26BFA\", \"decorated_queue_id\": \"4c18d4c1-968f-47f3-a658-77672f15b6c5_7574A26BFA\", \"x_sophos_email_id\": \"3c18d4c1-968f-47f3-a658-77672f15b6c5\", \"mime_message_id\": \"3c18d4c1-968f-47f3-a659\", \"submit_server_ip\": \"172.19.0.124\", \"client_ip\": \"172.19.102.214\", \"s3_resource_id\": \"/messages/doc1\", \"env_from\": { \"name\": \"\", \"domain_address\": \"sender.com\", \"local_address\": \"admin\", \"whole_address\": \"admin@sender.com\" }, \"env_recipient_list\": [{ \"name\": \"\", \"domain_address\": \"example.com\", \"local_address\": \"recipient1\", \"whole_address\": \"recipient1@example.com\" }], \"header_from\": { \"name\": \"\", \"domain_address\": \"sender.com\", \"local_address\": \"admin\", \"whole_address\": \"admin@sender.com\" }, \"header_to_list\": [{ \"name\": \"\", \"domain_address\": \"example.com\", \"local_address\": \"recipient1\", \"whole_address\": \"recipient1@example.com\" }, { \"name\": \"\", \"domain_address\": \"example.com\", \"local_address\": \"recipient2\", \"whole_address\": \"recipient2@example.com\" }], \"header_cc_list\": [{ \"name\": \"\", \"domain_address\": \"example.com\", \"local_address\": \"recipient3\", \"whole_address\": \"recipient3@example.com\" }], \"subject\": \"こんにちは世界\", \"direction\": \"INBOUND\", \"submit_type\": \"INTERNET\", \"release_type\": \"USER_RELEASE\", \"generate_mh_events\": true, \"first_seen_at\": \"2020-10-28T05:18:10.828Z\", \"effective_message_id\": \"5c18d4c1-968f-47f3-a658-77672f15b6c5\" } }, \"message_size_bytes\": 21095, \"customer_id\": \"d7a9521f-01f4-4894-9b90-27b0ba373ef2\", \"nonce\": \"not_supported\", \"accepting_server_ip\": \"172.20.0.150\", \"direction\": \"INBOUND\", \"message_key\": \"not_supported\", \"timestamp\": \"2020-11-17T17:39:23.510Z\", \"quarantine_reason\": null, \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"sender_ip\": \"34.253.219.134\", \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"sender\": \"admin@sasubr.com\", \"designation\": \"CLEAN\", \"action_context\": null, \"malware_designation\": \"UNKNOWN\", \"x_sophos_email_id\": \"5f1b8aed-bccd-46fc-aeaf-8a7046d7d41e\", \"delete_reason\": \"CUSTOMER_SPAM_SETTING\" }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        mh_mail_info = sqs_message.message_context['mh_mail_info']
        MH_MAIL_INFO_STORAGE_DIR = tempfile.mkdtemp()
        mh_mail_info_path = messagehistory.write_mh_mail_info(
            mh_mail_info,
            MH_MAIL_INFO_STORAGE_DIR
        )

        with io.open(mh_mail_info_path, 'r', encoding='utf8') as json_file:
            mh_mail_info_read = json.load(json_file)

        json1 = json.dumps(mh_mail_info, sort_keys=True)
        json2 = json.dumps(mh_mail_info_read['mail_info'], sort_keys=True)

        self.assertEqual(json1 == json2, True)

    def test_add_header(self):
        mh_mail_info_path = '/storage/mh-mail-info/217952ea-ba18-4224-9a93-61f166251db0'
        headers = {
            'X-Orig-Id': '455a800e-dcc1-453c-ac53-141541e2a7bb'
        }
        messagehistory.add_header(
            mh_mail_info_path,
            headers
        )
        self.assertEqual('X-Sophos-MH-Mail-Info-Path' in headers, True)
        self.assertEqual(
            headers['X-Sophos-MH-Mail-Info-Path'] == mh_mail_info_path, True)


if __name__ == "__main__":
    unittest.main()
