# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Representation of an notification submit info for notifier SQS

class NotificationSubmitInfo(object):
    def __init__(self,
                 notification_type,
                 sender_address,
                 recipients,
                 subject,
                 hostname,
                 failure_reason,
                 timestamp
                 ):

        self.notification_type = notification_type
        self.sender_address = sender_address
        self.recipients = recipients
        self.subject = subject
        self.hostname = hostname
        self.failure_reason = failure_reason
        self.timestamp = timestamp

    def __str__(self):
        sqs_printable = {
            'notification_type': self.notification_type,
            'sender_address': self.sender_address,
            'recipients': self.recipients,
            'subject': self.subject,
            'hostname': self.hostname,
            'failure_reason': self.failure_reason,
            'timestamp': self.timestamp
        }
        return ', '.join('%s=%s' % (key, value) for (key, value) in sqs_printable.iteritems())


    def get_sqs_json(self):
        sqs_json = {
            'notification_type': self.notification_type,
            'sender_address': self.sender_address,
            'recipients': self.recipients,
            'subject': self.subject,
            'hostname': self.hostname,
            'failure_reason': self.failure_reason,
            'timestamp': self.timestamp
        }
        return sqs_json
