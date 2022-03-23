#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2020, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Representation of E2E Telemetry data


class E2ETelemetryData:

    def __init__(self,
                 submit_queue_id,
                 direction,
                 latency,
                 timestamp,
                 email_product_type):
        self.submit_queue_id = submit_queue_id
        self.direction = direction
        self.latency = latency
        self.timestamp = timestamp
        self.email_product_type = email_product_type


    def get_e2e_telemetry_data_json(self):
        return self.__dict__

    def get_submit_queue_id(self):
        return self.submit_queue_id

    def get_direction(self):
        return self.direction

    def get_latency(self):
        return self.latency

    def get_timestamp(self):
        return self.timestamp

    def set_submit_queue_id(self, submit_queue_id):
        self.submit_queue_id = submit_queue_id

    def set_direction(self, direction):
        self.direction = direction

    def set_latency(self, latency):
        self.latency = latency

    def set_timestamp(self, timestamp):
        self.timestamp = timestamp

    def set_email_product_type(self, email_product_type):
        self.email_product_type = email_product_type

    def get_delivery_stream_json(self):
        delivery_stream_json = {
            'submit_queue_id': self.submit_queue_id,
            'direction': self.direction,
            'latency': self.latency,
            'timestamp': self.timestamp,
            'email_product_type': self.email_product_type
        }
        return delivery_stream_json
