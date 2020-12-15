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
import json
import logging
from awshandler import AwsHandler
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


def can_generate_mh_event(mail_info):
    if mail_info and 'generate_mh_events' in mail_info:
        return mail_info['generate_mh_events']
    else:
        return False


def get_mail_info(sqs_message, aws_region, policy_bucket_name):
    if sqs_message.message_context:
        if 'mh_mail_info' in sqs_message.message_context:
            return sqs_message.message_context['mh_mail_info']
        elif 'mail_info_s3_path' in sqs_message.message_context:
            try:
                return load_mail_info_file_from_S3(
                    aws_region,
                    policy_bucket_name,
                    sqs_message.message_context['mail_info_s3_path']
                )
            except Exception as e:
                logger.warn("Exception [{0}] while reading mh_mail_info from S3 [{1}]".format(
                    e, sqs_message.message_context['mail_info_s3_path']))
                return None
        else:
            return None
    else:
        return None


def load_mail_info_file_from_S3(aws_region, policy_bucket_name, file_name):
    try:
        awshandler = AwsHandler(aws_region)
        s3_data = awshandler.download_data_from_s3(
            policy_bucket_name, file_name)
        decompressed_content = mailinfoformatter.get_mh_mail_info(s3_data)
        logger.debug("Successfully retrieved mail info file from S3 bucket [{0}] for file [{1}]".format(
            policy_bucket_name,
            file_name
        ))
        return json.loads(decompressed_content)

    except (IOError, ClientError):
        logger.error(
            "Mail info file [{0}] does not exist or failed to read".format(file_name))


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
