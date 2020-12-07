# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Contains helper methods for Message History V2

import uuid
import io
import json

def can_generate_mh_event(sqs_message):
    if (sqs_message.message_context and
        'mh_mail_info' in sqs_message.message_context and
            'generate_mh_events' in sqs_message.message_context['mh_mail_info']):
        return sqs_message.message_context['mh_mail_info']['generate_mh_events']
    else:
        return False


def add_header(mh_mail_info_path, existing_headers):
    header_name = 'X-Sophos-MH-Mail-Info-Path'
    existing_headers[header_name] = mh_mail_info_path


def write_mh_mail_info(mh_mail_info, directory):
    """
    Writes the mh_mail_info to the provided directory. The filename is a newly created UUID.
    """
    filename = uuid.uuid4()
    full_path = '{0}/{1}'.format(directory, filename)

    json_to_write = {}
    json_to_write['mail_info'] = mh_mail_info
    with io.open(full_path, 'w', encoding='utf8') as json_file:
        data = json.dumps(json_to_write, encoding='utf8')
        json_file.write(unicode(data))
    return full_path
