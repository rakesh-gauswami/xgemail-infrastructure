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
import os

from sqsmessage import SqsMessage
from metadata import Metadata

#EmailProductType
EMAIL_PRODUCT_TYPE = "email_product_type"
GATEWAY = "Gateway"
MAILFLOW = "Mailflow"

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

    def get_sample_metadata(self, mh_mail_info):
        date_recorded = "2020-12-10T00:10:00Z"

        sender_address = None

        recipients_list = []

        metadata = Metadata(20201012,
                            mh_mail_info['client_ip'],
                            mh_mail_info['env_from']['whole_address'],
                            mh_mail_info['submit_server_ip'],
                            mh_mail_info['queue_id'],
                            date_recorded,
                            mh_mail_info['env_recipient_list'][0]['domain_address'],
                            recipients_list,
                            sender_address)
        return metadata


    def test_can_generate_mh_event_no_message_context(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\" }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        mail_info, can_generate_mh_event = messagehistory.get_mail_info(sqs_message, None, None)
        self.assertEqual(can_generate_mh_event, False)
        self.assertEqual(mail_info, None)
     

    def test_can_generate_mh_event_empty_message_context(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\": { \"mh_context\": {  } } }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        mail_info, can_generate_mh_event = messagehistory.get_mail_info(sqs_message, None, None)
        self.assertEqual(can_generate_mh_event, False)
        self.assertEqual(mail_info, None)

    def test_can_generate_mh_event_empty_mh_mail_info(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\": { \"mh_context\": {  \"mail_info\" : {} } } }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        mail_info, can_generate_mh_event = messagehistory.get_mail_info(sqs_message, None, None)
        self.assertEqual(can_generate_mh_event, False)
        self.assertEqual(mail_info, { 'mail_info': {}})

    def test_can_generate_mh_event_true(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\":  { \"mh_context\": { \"mail_info\" : { \"generate_mh_events\" : true} } } }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        mail_info, can_generate_mh_event = messagehistory.get_mail_info(sqs_message, None, None)
        self.assertEqual(can_generate_mh_event, True)
        self.assertEqual(mail_info, {'mail_info': { 'generate_mh_events': True}})

    def test_can_generate_mh_event_false(self):
        raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\": { \"mh_context\": { \"mail_info\" : { \"generate_mh_events\" : false} } } }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        mail_info, can_generate_mh_event = messagehistory.get_mail_info(sqs_message, None, None)
        self.assertEqual(can_generate_mh_event, False)
        self.assertEqual(mail_info, {'mail_info': { 'generate_mh_events': False}})

    def test_write_mh_mail_info(self):
        raw_sqs_message = "{ \"submit_message_type\": \"INTERNET\", \"reindex\": false, \"message_path_type\": \"NORMAL\", \"mailboxes\": [ \"user1@o365.qa1.sasubr.com\" ], \"akm_key\": \"not_supported\", \"event\": \"QUEUED_FOR_DELIVERY\", \"schema_version\": 20170224, \"message_context\":  {  \"module_scan_results\": { \"HRU\": { \"scan_result\": \"CLEAN\", \"early_out\": false, \"persist\": true }, \"SAVI\": { \"scan_result\": \"CLEAN\", \"early_out\": false, \"persist\": true } }, \"message_auth_results\": { \"spf_result\": \"HARDFAIL\", \"dkim_result\": \"NONE\", \"authentication_results\": [ \"mx-01-eu-central-1.qa.hydra.sophos.com\", \"spf=hardfail smtp.mailfrom=admin@sasubr.com\", \"dkim=none\" ] }, \"mh_context\": { \"mail_info\": { \"schema_version\": 20201026, \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"mailbox_id\": \"5f50ccbb5667b70dedc25b88\", \"mailbox_address\": \"recipient1@example.com\", \"queue_id\": \"7574A26BFA\", \"decorated_queue_id\": \"4c18d4c1-968f-47f3-a658-77672f15b6c5_7574A26BFA\", \"x_sophos_email_id\": \"3c18d4c1-968f-47f3-a658-77672f15b6c5\", \"mime_message_id\": \"3c18d4c1-968f-47f3-a659\", \"submit_server_ip\": \"172.19.0.124\", \"client_ip\": \"172.19.102.214\", \"s3_resource_id\": \"/messages/doc1\", \"env_from\": { \"name\": \"\", \"domain_address\": \"sender.com\", \"local_address\": \"admin\", \"whole_address\": \"admin@sender.com\" }, \"env_recipient_list\": [{ \"name\": \"\", \"domain_address\": \"example.com\", \"local_address\": \"recipient1\", \"whole_address\": \"recipient1@example.com\" }], \"header_from\": { \"name\": \"\", \"domain_address\": \"sender.com\", \"local_address\": \"admin\", \"whole_address\": \"admin@sender.com\" }, \"header_to_list\": [{ \"name\": \"\", \"domain_address\": \"example.com\", \"local_address\": \"recipient1\", \"whole_address\": \"recipient1@example.com\" }, { \"name\": \"\", \"domain_address\": \"example.com\", \"local_address\": \"recipient2\", \"whole_address\": \"recipient2@example.com\" }], \"header_cc_list\": [{ \"name\": \"\", \"domain_address\": \"example.com\", \"local_address\": \"recipient3\", \"whole_address\": \"recipient3@example.com\" }], \"subject\": \"こんにちは世界\", \"direction\": \"INBOUND\", \"submit_type\": \"INTERNET\", \"release_type\": \"USER_RELEASE\", \"generate_mh_events\": true, \"first_seen_at\": \"2020-10-28T05:18:10.828Z\", \"effective_message_id\": \"5c18d4c1-968f-47f3-a658-77672f15b6c5\" } } }, \"message_size_bytes\": 21095, \"customer_id\": \"d7a9521f-01f4-4894-9b90-27b0ba373ef2\", \"nonce\": \"not_supported\", \"accepting_server_ip\": \"172.20.0.150\", \"direction\": \"INBOUND\", \"message_key\": \"not_supported\", \"timestamp\": \"2020-11-17T17:39:23.510Z\", \"quarantine_reason\": null, \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"sender_ip\": \"34.253.219.134\", \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"sender\": \"admin@sasubr.com\", \"designation\": \"CLEAN\", \"action_context\": null, \"malware_designation\": \"UNKNOWN\", \"x_sophos_email_id\": \"5f1b8aed-bccd-46fc-aeaf-8a7046d7d41e\", \"delete_reason\": \"CUSTOMER_SPAM_SETTING\" }"
        sqs_message = self.parse_sqs_message(raw_sqs_message, "test")
        mh_mail_info = sqs_message.message_context['mh_context']['mail_info']
        MH_MAIL_INFO_STORAGE_DIR = tempfile.mkdtemp()
        mail_info, can_generate_mh_event = messagehistory.get_mail_info(sqs_message, None, None)

        mh_mail_info_path = messagehistory.write_mh_mail_info(
            mail_info,
            MH_MAIL_INFO_STORAGE_DIR
        )

        with io.open(MH_MAIL_INFO_STORAGE_DIR + '/' + mh_mail_info_path, 'r', encoding='utf8') as json_file:
            mh_mail_info_read = json.load(json_file)

        json1 = json.dumps(mh_mail_info, sort_keys=True)
        json2 = json.dumps(mh_mail_info_read['mail_info'], sort_keys=True)

        self.assertEqual(json1 == json2, True)

    def test_add_header(self):
        mh_mail_info_filename = '217952ea-ba18-4224-9a93-61f166251db0'
        headers = {
            'X-Orig-Id': '455a800e-dcc1-453c-ac53-141541e2a7bb'
        }
        messagehistory.add_header(
            mh_mail_info_filename,
            headers
        )
        self.assertEqual('X-Sophos-MH-Mail-Info-FileName' in headers, True)
        self.assertEqual(
            headers['X-Sophos-MH-Mail-Info-FileName'] == mh_mail_info_filename, True)

    # for testing in local
    # def test_read_mail_info_from_s3(self):
    #     raw_sqs_message = "{ \"schema_version\": 20170224, \"message_path\": \"messages/2020/11/17/17/bb9da2f8b7bc4e7594b4bf6cc1d91e992120a065dae6a4a89a33011f1f9866c2/172.20.0.150-4CbCqX0zJRzRhQm-o365.qa1.sasubr.com\", \"accepting_server_ip\": \"172.20.0.150\", \"queue_id\": \"4CbCqX0zJRzRhQm_UUID_a32958e5f18345e39096be8a077ed820\", \"akm_key\": \"not_supported\", \"nonce\": \"not_supported\", \"message_key\": \"not_supported\", \"message_path_type\": \"NORMAL\", \"submit_message_type\": \"INTERNET\", \"message_context\":  { \"mail_info_s3_path\" : \"messages/2020/12/14/15/00/172.19.0.92-5346826A9D-devtest.jpsbim.com.MAIL_INFO\" }}"
    #     sqs_message = self.parse_sqs_message(raw_sqs_message, "test")

    #     mail_info, can_generate_mh_event = messagehistory.get_mail_info(sqs_message, 'eu-west-1', 'tf-xgemail-msghistory-v2-eu-west-1-inf-bucket')
    #     print mail_info, can_generate_mh_event

    #     mh_mail_info = sqs_message.message_context['mail_info_s3_path']
    #     MH_MAIL_INFO_STORAGE_DIR = tempfile.mkdtemp()

    #     mh_mail_info_path = messagehistory.write_mh_mail_info(
    #         mail_info,
    #         MH_MAIL_INFO_STORAGE_DIR
    #     )

    #     with io.open(mh_mail_info_path, 'r', encoding='utf8') as json_file:
    #         mh_mail_info_read = json.load(json_file)

    #     json1 = json.dumps(mh_mail_info, sort_keys=True)
    #     json2 = json.dumps(mh_mail_info_read['mail_info_s3_path'], sort_keys=True)

    #     self.assertEqual(json1 == json2, True)

    def test_read_accepted_event(self):
        raw_accept_event = "{\"user_1@somedomain.com\": {\"mail_info\": {\"effective_message_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"client_ip\": \"172.19.102.214\", \"generate_mh_events\": true, \"header_to_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}], \"env_from\": {\"local_address\": \"admin\", \"domain_address\": \"senderdomain.com\", \"name\": \"\", \"whole_address\": \"admin@senderdomain.com\"}, \"header_cc_list\": [{\"local_address\": \"admin\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"admin@somedomain.com\"}], \"submit_server_ip\": \"172.19.0.124\", \"direction\": \"INBOUND\", \"mailbox_address\": \"user_1@somedomain.com\", \"first_seen_at\": \"2020-12-07T17:20:07.689Z\", \"x_sophos_email_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"submit_type\": \"INTERNET\", \"schema_version\": 20201026, \"queue_id\": \"ADE4326878\", \"mailbox_id\": \"5f50cf8e7390760cea68c09d\", \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"env_recipient_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}, {\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"subject\": \"Hi\"}, \"schema_version\": 20201026, \"event_info\": {\"server_type\": \"INTERNET_SUBMIT\", \"created_at\": \"2020-12-07T17:20:07.689Z\", \"sequence\": 100, \"schema_version\": 20201026, \"event\": \"ACCEPTED\", \"env_recipient_list\": [\"user_1@somedomain.com\", \"user_2@somedomain.com\"], \"reason_list\": [\"reason1\", \"reason2\"], \"id\": \"b4bb79c9-bd5a-43fc-9da8-266f909fd29a\"}},\"user_2@somedomain.com\": {\"mail_info\": {\"effective_message_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"client_ip\": \"172.19.102.214\", \"generate_mh_events\": true, \"header_to_list\": [{\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"env_from\": {\"local_address\": \"admin\", \"domain_address\": \"senderdomain.com\", \"name\": \"\", \"whole_address\": \"admin@senderdomain.com\"}, \"header_cc_list\": [{\"local_address\": \"admin\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"admin@somedomain.com\"}], \"submit_server_ip\": \"172.19.0.124\", \"direction\": \"INBOUND\", \"mailbox_address\": \"user_2@somedomain.com\", \"first_seen_at\": \"2020-12-07T17:20:07.689Z\", \"x_sophos_email_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c01\", \"submit_type\": \"INTERNET\", \"schema_version\": 20201026, \"queue_id\": \"ADE4326878\", \"mailbox_id\": \"5f50cf8e7390760cea68c09d\", \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"env_recipient_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}, {\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"subject\": \"Hi\"}, \"schema_version\": 20201026, \"event_info\": {\"server_type\": \"INTERNET_SUBMIT\", \"created_at\": \"2020-12-07T17:20:07.689Z\", \"sequence\": 100, \"schema_version\": 20201026, \"event\": \"ACCEPTED\", \"env_recipient_list\": [\"user_1@somedomain.com\", \"user_2@somedomain.com\"], \"reason_list\": [\"reason1\", \"reason2\"], \"id\": \"b4bb79c9-bd5a-43fc-9da8-266f909fd29b\"}}}"
        policy = "{\"user1@somedomain.com\": { 		\"xgemail/cxmail/enabled\": true, 		\"xgemail/has_feature\": true, 		\"xgemail/quarantine_summary/days\": [ 			0, 			1, 			3, 			4, 			6 		], 		\"xgemail/quarantine_summary/enabled\": true, 		\"xgemail/quarantine_summary/hours\": [ 			4 		], 		\"xgemail/quarantine_summary/timezone\": \"UTC\", 		\"xgemail/spam/blatant_disposition\": \"DELETE\", 		\"xgemail/spam/bulk_custom_setting\": \"QUARANTINE\", 		\"xgemail/spam/confirmed_custom_setting\": \"QUARANTINE\", 		\"xgemail/spam/filter_strength\": \"HIGH\", 		\"xgemail/spam/non_spam_custom_setting\": \"SEND\", 		\"xgemail/spam/suspected_custom_setting\": \"DELAY\", 		\"xgemail/spam/use_custom_settings\": true, 		\"xgemail/spf/enabled\": true, 		\"xgemail/spf/action\": \"QUARANTINE\", 		\"xgemail/spf/tag\": \"[SPF FAILED]\", 		\"xgemail/spoofing/enabled\": false, 		\"xgemail/spoofing/disposition\": \"TAG\", 		\"xgemail/spoofing/tag\": \"SPOOFED\", 		\"xgemail/dkim/enabled\": true, 		\"xgemail/dkim/action\": \"DELIVER\", 		\"xgemail/dkim/tag\": \"[DKIM FAILED]\", 		\"xgemail/dmarc/enabled\": true, 		\"xgemail/dmarc/action\": \"REJECT\", 		\"xgemail/dmarc/tag\": \"[DMARC KIND OF FAILED]\", 		\"xgemail/toc/enabled\": false, 		\"xgemail/toc/action/high_risk\": \"BLOCK\", 		\"xgemail/toc/action/med_risk\": \"BLOCK\", 		\"xgemail/toc/action/low_risk\": \"ALLOW\", 		\"xgemail/toc/action/unknown_risk\": \"WARN\", 		\"xgemail/toc/rewrite/plain_message\": true, 		\"xgemail/toc/rewrite/signed_message\": true, 		\"xgemail/sandstorm/enabled\": true, 		\"xgemail/sandstorm/region\": \"EU_WEST_2\", 		\"xgemail/smart_banner/enabled\": true, 		\"xgemail/smart_banner/trusted/enabled\": true, 		\"xgemail/smart_banner/unknown/enabled\": false, 		\"xgemail/smart_banner/untrusted/enabled\": false, 		\"xgemail/smart_banner/trusted/message\": \"This sender is trusted.\", 		\"xgemail/smart_banner/unknown/message\": \"Caution! This message was sent from outside your organization.\", 		\"xgemail/unscannable_content/enabled\": true, 		\"xgemail/unscannable_content/dispositon\": \"DELIVER\", 		\"xgemail/impersonation/enabled\": true, 		\"xgemail/impersonation/action\": \"ADD_BANNER\" 	} }"
        jilter_context = {"msghistory_events":raw_accept_event,"policy":policy}
        #Write jilter_context to disk as jilter does.
        MH_EVENT_STORAGE_DIR = tempfile.mkdtemp()
        QUEUE_ID = "ADE4326878"
        full_path = MH_EVENT_STORAGE_DIR + '/' + QUEUE_ID
     
        with io.open(full_path, 'w', encoding='utf8') as json_file:
          json_file.write(unicode(jilter_context))

        expected_jilter_context = json.loads(raw_accept_event)

        #Read jilter_context  from disk.
        actual_jilter_context = messagehistory.read_jilter_context(QUEUE_ID, MH_EVENT_STORAGE_DIR)

        #Check if it matches.
        expected_json = json.dumps(expected_jilter_context, sort_keys=True)
        actual_json = json.dumps(actual_jilter_context, sort_keys=True)

    def test_update_accepted_event_inbound(self):
        #Accepted events json for two users. 
        raw_accept_event = "{\"user_1@somedomain.com\": {\"mail_info\": {\"effective_message_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"client_ip\": \"172.19.102.214\", \"generate_mh_events\": true, \"header_to_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}], \"env_from\": {\"local_address\": \"admin\", \"domain_address\": \"senderdomain.com\", \"name\": \"\", \"whole_address\": \"admin@senderdomain.com\"}, \"header_cc_list\": [{\"local_address\": \"admin\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"admin@somedomain.com\"}], \"submit_server_ip\": \"172.19.0.124\", \"direction\": \"INBOUND\", \"mailbox_address\": \"user_1@somedomain.com\", \"first_seen_at\": \"2020-12-07T17:20:07.689Z\", \"x_sophos_email_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"submit_type\": \"INTERNET\", \"schema_version\": 20201026, \"queue_id\": \"ADE4326878\", \"mailbox_id\": \"5f50cf8e7390760cea68c09d\", \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"env_recipient_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}, {\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"subject\": \"Hi\"}, \"schema_version\": 20201026, \"event_info\": {\"server_type\": \"INTERNET_SUBMIT\", \"created_at\": \"2020-12-07T17:20:07.689Z\", \"sequence\": 100, \"schema_version\": 20201026, \"event\": \"ACCEPTED\", \"env_recipient_list\": [\"user_1@somedomain.com\", \"user_2@somedomain.com\"], \"reason_list\": [\"reason1\", \"reason2\"], \"id\": \"b4bb79c9-bd5a-43fc-9da8-266f909fd29a\"}},\"user_2@somedomain.com\": {\"mail_info\": {\"effective_message_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"client_ip\": \"172.19.102.214\", \"generate_mh_events\": true, \"header_to_list\": [{\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"env_from\": {\"local_address\": \"admin\", \"domain_address\": \"senderdomain.com\", \"name\": \"\", \"whole_address\": \"admin@senderdomain.com\"}, \"header_cc_list\": [{\"local_address\": \"admin\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"admin@somedomain.com\"}], \"submit_server_ip\": \"172.19.0.124\", \"direction\": \"INBOUND\", \"mailbox_address\": \"user_2@somedomain.com\", \"first_seen_at\": \"2020-12-07T17:20:07.689Z\", \"x_sophos_email_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c01\", \"submit_type\": \"INTERNET\", \"schema_version\": 20201026, \"queue_id\": \"ADE4326878\", \"mailbox_id\": \"5f50cf8e7390760cea68c09d\", \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"env_recipient_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}, {\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"subject\": \"Hi\"}, \"schema_version\": 20201026, \"event_info\": {\"server_type\": \"INTERNET_SUBMIT\", \"created_at\": \"2020-12-07T17:20:07.689Z\", \"sequence\": 100, \"schema_version\": 20201026, \"event\": \"ACCEPTED\", \"env_recipient_list\": [\"user_1@somedomain.com\", \"user_2@somedomain.com\"], \"reason_list\": [\"reason1\", \"reason2\"], \"id\": \"b4bb79c9-bd5a-43fc-9da8-266f909fd29b\"}}}"
  
        #Read accepted event for two users.
        accept_events = json.loads(raw_accept_event)
    
        user_1 = 'User_1@somedomain.com'
        user_2 = 'user_2@somedomain.com'
        sender = 'admin@senderdomain.com'

        #Prepare metadata
        metadata = self.get_sample_metadata(accept_events[user_1.lower()]['mail_info'])

        recipients = []
        recipients.append(user_1) #Recipient address is in upper case. But in accepted event json it is in lower case.

        s3_file_path = '/messages/2020/12/10/00/xyz'

        #Apply metadata to one user.
        messagehistory.update_msghistory_event(accept_events, s3_file_path, metadata, 'INBOUND', recipients, sender, GATEWAY)
       
        #Check mail info is updated with s3 path for user_1 and not user_2.
        self.assertEqual(accept_events[user_1.lower()]['mail_info']['s3_resource_id'], s3_file_path)
        self.assertFalse('s3_resource_id' in accept_events[user_2.lower()]['mail_info'])
        self.assertEqual(accept_events[user_1.lower()]['mail_info'][EMAIL_PRODUCT_TYPE], GATEWAY)

        #Replace the queue id with decorated queue id. 
        metadata.add_uuid_to_queue_id()

        #Apply metadata to one user.
        messagehistory.update_msghistory_event(accept_events, s3_file_path, metadata, 'INBOUND', recipients, sender, MAILFLOW)

        #Ensure for that user mail_info now has decorated queue id information as well.
        self.assertEqual(accept_events[user_1.lower()]['mail_info']['decorated_queue_id'], metadata.get_queue_id())
        self.assertFalse('decorated_queue_id' in accept_events[user_2.lower()]['mail_info'])
        self.assertEqual(accept_events[user_1.lower()]['mail_info'][EMAIL_PRODUCT_TYPE], MAILFLOW)

    def test_update_accepted_event_outbound(self):
        raw_accept_event =  "{\"admin@senderdomain.com\": {\"mail_info\": {\"effective_message_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"client_ip\": \"172.19.102.214\", \"generate_mh_events\": true, \"header_to_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}], \"env_from\": {\"local_address\": \"admin\", \"domain_address\": \"senderdomain.com\", \"name\": \"\", \"whole_address\": \"admin@senderdomain.com\"}, \"header_cc_list\": [{\"local_address\": \"admin\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"admin@somedomain.com\"}], \"submit_server_ip\": \"172.19.0.124\", \"direction\": \"OUTBOUND\", \"mailbox_address\": \"admin@senderdomain.com\", \"first_seen_at\": \"2020-12-07T17:20:07.689Z\", \"x_sophos_email_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"submit_type\": \"INTERNET\", \"schema_version\": 20201026, \"queue_id\": \"ADE4326878\", \"mailbox_id\": \"5f50cf8e7390760cea68c09d\", \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"env_recipient_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}], \"subject\": \"Hi\"}, \"schema_version\": 20201026, \"event_info\": {\"server_type\": \"INTERNET_SUBMIT\", \"created_at\": \"2020-12-07T17:20:07.689Z\", \"sequence\": 100, \"schema_version\": 20201026, \"event\": \"ACCEPTED\", \"env_recipient_list\": [\"user_1@somedomain.com\", \"user_2@somedomain.com\"], \"reason_list\": [\"reason1\", \"reason2\"], \"id\": \"b4bb79c9-bd5a-43fc-9da8-266f909fd29a\"}}}"

        #Read accepted event for two users.
        accept_events = json.loads(raw_accept_event)

        sender = 'Admin@senderdomain.com'

        #Prepare metadata
        metadata = self.get_sample_metadata(accept_events[sender.lower()]['mail_info'])

        recipients = []
        recipients.append(sender.lower()) #To make sure we are not considering recipients when direction is outbound.

        s3_file_path = '/messages/2020/12/10/00/xyz'

        messagehistory.update_msghistory_event(accept_events, s3_file_path, metadata, 'OUTBOUND', recipients, 'someothersender@senderdomain.com', GATEWAY)
        self.assertFalse('s3_resource_id' in accept_events[sender.lower()]['mail_info']) #Because we used incorrect sender in above line.
        self.assertFalse(EMAIL_PRODUCT_TYPE in accept_events[sender.lower()]['mail_info'])

        recipients = []
        metadata.add_uuid_to_queue_id()

        messagehistory.update_msghistory_event(accept_events, s3_file_path, metadata, 'OUTBOUND', recipients, sender, MAILFLOW)

        self.assertEqual(accept_events[sender.lower()]['mail_info']['s3_resource_id'], s3_file_path)
        self.assertEqual(accept_events[sender.lower()]['mail_info']['decorated_queue_id'], metadata.get_queue_id())
        self.assertEqual(accept_events[sender.lower()]['mail_info'][EMAIL_PRODUCT_TYPE], MAILFLOW)

    def test_delete_msghistory_events_file(self):
        raw_accept_event_two_recipients = "{\"user_1@somedomain.com\": {\"mail_info\": {\"effective_message_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"client_ip\": \"172.19.102.214\", \"generate_mh_events\": true, \"header_to_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}], \"env_from\": {\"local_address\": \"admin\", \"domain_address\": \"senderdomain.com\", \"name\": \"\", \"whole_address\": \"admin@senderdomain.com\"}, \"header_cc_list\": [{\"local_address\": \"admin\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"admin@somedomain.com\"}], \"submit_server_ip\": \"172.19.0.124\", \"direction\": \"INBOUND\", \"mailbox_address\": \"user_1@somedomain.com\", \"first_seen_at\": \"2020-12-07T17:20:07.689Z\", \"x_sophos_email_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"submit_type\": \"INTERNET\", \"schema_version\": 20201026, \"queue_id\": \"ADE4326878\", \"mailbox_id\": \"5f50cf8e7390760cea68c09d\", \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"env_recipient_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}, {\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"subject\": \"Hi\"}, \"schema_version\": 20201026, \"event_info\": {\"server_type\": \"INTERNET_SUBMIT\", \"created_at\": \"2020-12-07T17:20:07.689Z\", \"sequence\": 100, \"schema_version\": 20201026, \"event\": \"ACCEPTED\", \"env_recipient_list\": [\"user_1@somedomain.com\", \"user_2@somedomain.com\"], \"reason_list\": [\"reason1\", \"reason2\"], \"id\": \"b4bb79c9-bd5a-43fc-9da8-266f909fd29a\"}},\"user_2@somedomain.com\": {\"mail_info\": {\"effective_message_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"client_ip\": \"172.19.102.214\", \"generate_mh_events\": true, \"header_to_list\": [{\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"env_from\": {\"local_address\": \"admin\", \"domain_address\": \"senderdomain.com\", \"name\": \"\", \"whole_address\": \"admin@senderdomain.com\"}, \"header_cc_list\": [{\"local_address\": \"admin\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"admin@somedomain.com\"}], \"submit_server_ip\": \"172.19.0.124\", \"direction\": \"INBOUND\", \"mailbox_address\": \"user_2@somedomain.com\", \"first_seen_at\": \"2020-12-07T17:20:07.689Z\", \"x_sophos_email_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c01\", \"submit_type\": \"INTERNET\", \"schema_version\": 20201026, \"queue_id\": \"ADE4326878\", \"mailbox_id\": \"5f50cf8e7390760cea68c09d\", \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"env_recipient_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}, {\"local_address\": \"user_2\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_2@somedomain.com\"}], \"subject\": \"Hi\"}, \"schema_version\": 20201026, \"event_info\": {\"server_type\": \"INTERNET_SUBMIT\", \"created_at\": \"2020-12-07T17:20:07.689Z\", \"sequence\": 100, \"schema_version\": 20201026, \"event\": \"ACCEPTED\", \"env_recipient_list\": [\"user_1@somedomain.com\", \"user_2@somedomain.com\"], \"reason_list\": [\"reason1\", \"reason2\"], \"id\": \"b4bb79c9-bd5a-43fc-9da8-266f909fd29b\"}}}"
        
        #Write accept event to disk as jilter does.
        MH_EVENT_STORAGE_DIR = tempfile.mkdtemp()
        QUEUE_ID = "ADE4326878"
        file_path = MH_EVENT_STORAGE_DIR + '/' + QUEUE_ID
     
        with io.open(file_path, 'w', encoding='utf8') as json_file:
          json_file.write(unicode(raw_accept_event_two_recipients))

        accept_events = json.loads(raw_accept_event_two_recipients)

        messagehistory.delete_msghistory_events_file(accept_events.values()[0]['mail_info'], QUEUE_ID, MH_EVENT_STORAGE_DIR)

        #File should not deleted 
        self.assertTrue(os.path.exists(file_path))

        raw_accept_event_single_recipient =  "{\"user_1@somedomain.com\": {\"mail_info\": {\"effective_message_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"client_ip\": \"172.19.102.214\", \"generate_mh_events\": true, \"header_to_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}], \"env_from\": {\"local_address\": \"admin\", \"domain_address\": \"senderdomain.com\", \"name\": \"\", \"whole_address\": \"admin@senderdomain.com\"}, \"header_cc_list\": [{\"local_address\": \"admin\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"admin@somedomain.com\"}], \"submit_server_ip\": \"172.19.0.124\", \"direction\": \"INBOUND\", \"mailbox_address\": \"user_1@somedomain.com\", \"first_seen_at\": \"2020-12-07T17:20:07.689Z\", \"x_sophos_email_id\": \"eeb19bed-a4b0-4437-b8c4-1d76acea8c00\", \"submit_type\": \"INTERNET\", \"schema_version\": 20201026, \"queue_id\": \"ADE4326878\", \"mailbox_id\": \"5f50cf8e7390760cea68c09d\", \"customer_id\": \"b385bb51-1533-447c-b71a-8084c028421d\", \"env_recipient_list\": [{\"local_address\": \"user_1\", \"domain_address\": \"somedomain.com\", \"name\": \"\", \"whole_address\": \"user_1@somedomain.com\"}], \"subject\": \"Hi\"}, \"schema_version\": 20201026, \"event_info\": {\"server_type\": \"INTERNET_SUBMIT\", \"created_at\": \"2020-12-07T17:20:07.689Z\", \"sequence\": 100, \"schema_version\": 20201026, \"event\": \"ACCEPTED\", \"env_recipient_list\": [\"user_1@somedomain.com\", \"user_2@somedomain.com\"], \"reason_list\": [\"reason1\", \"reason2\"], \"id\": \"b4bb79c9-bd5a-43fc-9da8-266f909fd29a\"}}}"

        with io.open(file_path, 'w', encoding='utf8') as json_file:
          json_file.write(unicode(raw_accept_event_single_recipient))

        accept_events = json.loads(raw_accept_event_single_recipient)
        messagehistory.delete_msghistory_events_file(accept_events.values()[0]['mail_info'], QUEUE_ID, MH_EVENT_STORAGE_DIR)

        #File should be deleted  as only one recipient in message
        self.assertFalse(os.path.exists(file_path))

if __name__ == "__main__":
    unittest.main()
