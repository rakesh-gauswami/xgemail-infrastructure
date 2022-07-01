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
import logging
from awshandler import AwsHandler
import requests
import mailinfoformatter
from logging.handlers import SysLogHandler
from botocore.exceptions import ClientError

# logging to syslog setup
logger = logging.getLogger('message-history')
logger.setLevel(logging.INFO)
syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
syslog_handler.formatter = formatter
logger.addHandler(syslog_handler)

INBOUND_MESSAGE_DIRECTION = "INBOUND"
OUTBOUND_MESSAGE_DIRECTION = "OUTBOUND"
EMAIL_PRODUCT_TYPE = "email_product_type"


def can_generate_mh_event(mail_info):
    if mail_info and 'generate_mh_events' in mail_info:
        return mail_info['generate_mh_events']
    else:
        return False


def get_mail_info(sqs_message, aws_region, msg_history_v2_bucket):
    if sqs_message.message_context:
        if ('mh_context' in sqs_message.message_context and
            'mail_info' in sqs_message.message_context['mh_context'] and
            sqs_message.message_context['mh_context']['mail_info'] != None):
            mail_info = sqs_message.message_context['mh_context']['mail_info']
            json = { 'mail_info' : sqs_message.message_context['mh_context']['mail_info'] }
            return json, can_generate_mh_event(mail_info)
        elif ('mh_context' in sqs_message.message_context and
              'mail_info_s3_path' in sqs_message.message_context['mh_context'] and
              sqs_message.message_context['mh_context']['mail_info_s3_path'] != None):
            try:
                mail_info_s3 = load_mail_info_file_from_S3(
                    aws_region,
                    msg_history_v2_bucket,
                    sqs_message.message_context['mh_context']['mail_info_s3_path']
                )
                json = { 'mail_info_s3_path' : sqs_message.message_context['mh_context']['mail_info_s3_path'] }
                return json, can_generate_mh_event(mail_info_s3)
            except Exception as e:
                logger.warn("Exception [{0}] while reading mh_mail_info from S3 [{1}]".format(
                    e, sqs_message.message_context['mh_context']['mail_info_s3_path']))
                return None, False
        else:
            return None, False
    else:
        return None, False


def load_mail_info_file_from_S3(aws_region, msg_history_v2_bucket, file_name):
    try:
        awshandler = AwsHandler(aws_region)
        s3_data = awshandler.download_data_from_s3(
            msg_history_v2_bucket, file_name)
        decompressed_content = mailinfoformatter.get_mh_mail_info(s3_data)
        logger.debug("Successfully retrieved mail info file from S3 bucket [{0}] for file [{1}]".format(
            msg_history_v2_bucket,
            file_name
        ))
        return json.loads(decompressed_content)

    except (IOError, ClientError):
        logger.error(
            "Mail info file [{0}] does not exist or failed to read".format(file_name))


def add_header(mh_mail_info_filename, existing_headers):
    header_name = 'X-Sophos-MH-Mail-Info-FileName'
    existing_headers[header_name] = mh_mail_info_filename


def write_mh_mail_info(json_to_write, directory):
    """
    Writes the mh_mail_info to the provided directory. The filename is a newly created UUID.
    """
    filename = str(uuid.uuid4())
    full_path = '{0}/{1}'.format(directory, filename)

    with io.open(full_path, 'w', encoding='utf8') as json_file:
        data = json.dumps(json_to_write, encoding='utf8')
        json_file.write(unicode(data))
    return filename

def read_jilter_context(queue_id, directory):
    """
    Reads and return the meta information written by the Jilters.
    E.g
    {
        "msghistory_events": ["mailbox":MesageHistoryEventObj,....],
        "policy": ["recipient":"policy_attributes"],
        Can be extended further for other info
    }
    """
    jilter_context = {}
    try:
        with io.open(directory + '/' + queue_id, encoding='utf8') as f:
            jilter_context = json.load(f)
            return jilter_context
    except Exception as ex:
        logger.debug("Queue Id:[{0}]. Error reading accepted events: [{1}]".format(queue_id, ex))
        return jilter_context

def update_msghistory_event_inbound(msghistory_events, s3_file_path, policy_metadata, recipients, email_product_type):
    for recipient in recipients:
      recipient = recipient.lower()
      if recipient in msghistory_events:
        if msghistory_events[recipient]['mail_info']['queue_id'] != policy_metadata.get_queue_id():
            msghistory_events[recipient]['mail_info']['decorated_queue_id'] = policy_metadata.get_queue_id()
        msghistory_events[recipient]['mail_info']['s3_resource_id'] = s3_file_path
        msghistory_events[recipient]['mail_info'][EMAIL_PRODUCT_TYPE] = email_product_type

def update_msghistory_event_outbound(msghistory_events, s3_file_path, policy_metadata, sender, email_product_type):
    sender = sender.lower()
    if sender in msghistory_events:
        if msghistory_events[sender]['mail_info']['queue_id'] != policy_metadata.get_queue_id():
            msghistory_events[sender]['mail_info']['decorated_queue_id'] = policy_metadata.get_queue_id()
        msghistory_events[sender]['mail_info']['s3_resource_id'] = s3_file_path
        msghistory_events[sender]['mail_info'][EMAIL_PRODUCT_TYPE] = email_product_type


def update_msghistory_event(msghistory_events, s3_file_path, policy_metadata, direction, recipients, sender, email_product_type):
    """
    Updates the accepted events of the given recipients with the S3 file path and decorated_queue_id. 
    """
    if direction == INBOUND_MESSAGE_DIRECTION:
        update_msghistory_event_inbound(msghistory_events, s3_file_path, policy_metadata, recipients, email_product_type)
    else:
        update_msghistory_event_outbound(msghistory_events, s3_file_path, policy_metadata, sender, email_product_type)

def send_msghistory_events(queue_id, msghistory_events, url):
    """
    Post the list of events to the given url
    """
    try:
      headers = {'Content-Type': 'application/json' , 'X-QUEUE-ID' : queue_id, 'Connection' : 'close'}
      r = requests.post(url, data=json.dumps(msghistory_events), headers=headers)
      logger.debug("Received response from MessageHistoryEventProcessor with status [{0}]".format(r.status_code))
      r.close()
    except Exception as ex:
      logger.warning("Queue Id:[{0}]. Error sending MH events: [{1}]".format(queue_id, ex))

def handle_msghistory_events(queue_id, msghistory_events, url, event_dir):
    """
    Post the list of events which has 's3_resource_id' to the given url
    """    
    try:
      #We could have read events for more recipients from the file than the list of recipients for which this producer script was called by postfix.
      events_list = []
      for event in msghistory_events.values():
        if  's3_resource_id' in event['mail_info']:
            events_list.append(event)
     
      send_msghistory_events(queue_id, events_list, url)

      #We can send any mail_info to 'delete_msghistory_events_file' . All are same.
      delete_msghistory_events_file(msghistory_events.values()[0]['mail_info'], queue_id, event_dir)
    except Exception as ex:
      logger.warning("Queue Id [{0}]. Error in sending message history event [{1}]".format(queue_id, ex))

def delete_msghistory_events_file(mail_info, queue_id, directory):
    """
    Deletes the accepted events file written by Jilter. This is done only if
    number of envelope recipients is equal to 1.
    """

    try:
      if (mail_info['env_recipient_list']  is not None  and
             len(mail_info['env_recipient_list']) == 1):
        #Delete the file written by jilter.
        os.remove(directory + '/' + queue_id)
    except Exception as ex:
        logger.warning("Queue Id:[{0}]. Error deleteing MH accepted events file: [{1}]".format(queue_id, ex))
