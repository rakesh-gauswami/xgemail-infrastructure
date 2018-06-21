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
# Representation of a delivery status queue log

class QueueLog:
    def __init__(self,
                 schema_version,
                 server_type,
                 server_ip,
                 queue_id,
                 nullable_dsn_code,
                 timestamp):
        self.__schema_version = schema_version
        self.__server_type = server_type
        self.__server_ip = server_ip
        self.__queue_id = queue_id
        self.__nullable_dsn_code = nullable_dsn_code
        self.__timestamp = timestamp

    def __str__(self):
        delivery_status_queue_log_json = self.get_queue_log_json()
        return ', '.join('%s=%s' % (key, value) for (key, value) in delivery_status_queue_log_json.iteritems())

    def get_queue_log_json(self):
        return {
            'schema_version': self.__schema_version,
            'server_type': self.__server_type,
            'server_ip': self.__server_ip,
            'queue_id': self.__queue_id,
            'dsn_code': self.__nullable_dsn_code
            if self.__nullable_dsn_code is not None else 'null',
            'timestamp': self.__timestamp
        }

    @property
    def schema_version(self):
        return self.__schema_version

    @property
    def server_type(self):
        return self.__server_type

    @property
    def server_ip(self):
        return self.__server_ip

    @property
    def queue_id(self):
        return self.__queue_id

    @property
    def nullable_dsn_code(self):
        return self.__nullable_dsn_code

    @property
    def timestamp(self):
        return self.__timestamp
