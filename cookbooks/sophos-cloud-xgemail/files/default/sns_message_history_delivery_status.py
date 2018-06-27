#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2018    , Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Representation of a message to be sent to Message History Delivery Status queue
from queue_log import QueueLog


class SnsMessageHistoryDeliveryStatus:
    def __init__(self,
                 direction,
                 message_path,
                 queue_log,
                 nullable_next_queue_log):
        self.__direction = direction
        self.__message_path = message_path
        self.__queue_log = queue_log
        self.__nullable_next_queue_log = nullable_next_queue_log

    def get_sns_message_history_delivery_status_json(self):
        return {
            'direction': self.__direction,
            'message_path': self.__message_path,
            'queue_log': self.__queue_log.get_queue_log_json() if self.__queue_log is not None else 'null',
            'next_queue_log': self.__nullable_next_queue_log.get_queue_log_json() if self.__nullable_next_queue_log is not None else 'null'
        }

    @property
    def direction(self):
        return self.__direction

    @property
    def message_path(self):
        return self.__message_path

    @property
    def queue_log(self):
        return self.__queue_log

    @property
    def nullable_next_queue_log(self):
        return self.__nullable_next_queue_log

    def __str__(self):
        json_format = self.get_sns_message_history_delivery_status_json()
        return ', '.join('%s=%s' % (key, value) for (key, value) in json_format.iteritems())
