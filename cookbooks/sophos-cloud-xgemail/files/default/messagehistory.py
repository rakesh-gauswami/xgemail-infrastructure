# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2020, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Contains helper methods for Message History V2

import uuid
import io
import os
import json
import requests
import logging

# logging to syslog setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

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

def read_msghistory_accepted_events(queue_id, directory):
    """
    Reads the accepted events information written by the Jilters.
    """

    msghistory_events = None

    try:
      with io.open(directory + '/' + queue_id, encoding='utf8') as f:
        msghistory_events = json.load(f)
        return msghistory_events
    except Exception as ex:
      logger.warning("Error reading accepted events: [{0}]".format(ex))

def update_msghistory_event(msghistory_events, s3_file_path, policy_metadata, recipients):
    """
    Updates the accepted events of the given recipients with the S3 file path and decorated_queue_id. 
    """
    for recipient in recipients:
        if recipient in msghistory_events.keys():
            if msghistory_events[recipient]['mail_info']['queue_id'] != policy_metadata.get_queue_id():
                msghistory_events[recipient]['mail_info']['decorated_queue_id'] = policy_metadata.get_queue_id()
            msghistory_events[recipient]['mail_info']['s3_resource_id'] = s3_file_path

def send_msghistory_events(msghistory_events, url):
    """
    Post the list of events to the given url
    """
    try:
      headers = {'Content-Type': 'application/json' }
      r = requests.post(url, data=json.dumps(msghistory_events), headers=headers)
      logger.debug("Received response from MessageHistoryEventProcessor with status [{0}]".format(r.status_code))
    except Exception as ex:
      logger.warning("Error sending MH events: [{0}]".format(ex))

def delete_msghistory_events_file(msghistory_events, queue_id, directory):
    """
    Deletes the accepted events file written by Jilter. This is done only if
    number of envelope recipients is equal to 1.
    """

    try:
      mail_info = msghistory_events[0]['mail_info']
      if (mail_info['env_recipient_list']  is not None  and
             len(mail_info['env_recipient_list']) == 1):
        #Delete the file written by jilter.
        os.remove(directory + '/' + queue_id)
    except Exception as ex:
        logger.warning("Error deleteing MH accepted events file: [{0}]".format(ex))