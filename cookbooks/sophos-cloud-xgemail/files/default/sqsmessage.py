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
# Representation of a message in SQS

class SqsMessage:
    def __init__(self,
                 schema_version,
                 message_path,
                 accepting_server_ip,
                 queue_id,
                 akm_key,
                 nonce,
                 message_key,
                 submit_message_type,
                 receipt=None,
                 policy_hash=None):
        self.schema_version = schema_version
        self.message_path = message_path
        self.accepting_server_ip = accepting_server_ip
        self.queue_id = queue_id
        self.akm_key = akm_key
        self.nonce = nonce
        self.message_key = message_key
        self.submit_message_type = submit_message_type
        self.receipt = receipt
        self.policy_hash = policy_hash

    def __str__(self):
        sqs_printable = {
            'schema_version': self.schema_version,
            'message_path': self.message_path,
            'accepting_server_ip': self.accepting_server_ip,
            'queue_id': self.queue_id,
            'submit_message_type': self.submit_message_type
        }
        return ', '.join('%s=%s' % (key, value) for (key, value) in sqs_printable.iteritems())


    def get_sqs_json(self):
        sqs_json = {
            'schema_version': self.schema_version,
            'message_path': self.message_path,
            'accepting_server_ip': self.accepting_server_ip,
            'queue_id': self.queue_id,
            'akm_key': self.akm_key,
            'nonce': self.nonce,
            'message_key': self.message_key,
            'submit_message_type': self.submit_message_type,
            'policy_hash': self.policy_hash
        }
        return sqs_json
