#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Polls XGEMAIL PIC for a list of customer domains
#
# Copyright: Copyright (c) 1997-2016. All rights reserved.
# Company: Sophos Limited or one of its affiliates.

import argparse
import boto3
import base64
import json
import os
import requests
import subprocess
import sys
import logging

from requests_toolbelt import (MultipartEncoder,
                               MultipartEncoderMonitor)
from logging.handlers import SysLogHandler

# Constants
PIC_FQDN = 'mail-cloudstation-eu-west-1.dev.hydra.sophos.com'
MAIL_PIC_RESPONSE_TIMEOUT = 60
MAIL_PIC_API_AUTH = 'xgemail-eu-west-1-mail'
CONNECTIONS_BUCKET = 'cloud-dev-connections'

# Logging to syslog setup
logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger('allow-block-importer')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
# handler = logging.handlers.SysLogHandler('/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
handler.formatter = formatter
logger.addHandler(handler)

ACCOUNT = 'dev'

def get_api_url():
    if ACCOUNT == 'sandbox':
        return 'http://{0}/mail-services/api/xgemail'.format(PIC_FQDN)
    return 'https://{0}/mail/api/xgemail'.format(PIC_FQDN)

IMPORTER_URL = get_api_url() + '/allow-block/import'

def get_passphrase():
    s3 = boto3.client('s3')
    passphrase = s3.get_object(Bucket=CONNECTIONS_BUCKET, Key=MAIL_PIC_API_AUTH)
    return base64.b64encode('mail:' + passphrase['Body'].read())

def get_headers():
    if ACCOUNT == 'sandbox':
        return { 'Authorization': 'Basic' }
    return { 'Authorization': 'Basic ' + get_passphrase() }

def callback(monitor):
    logger.info("Bytes read: {0}".format(monitor.bytes_read))

def split_files(file_path):
    

def upload_allow_block_lists(file_path, customer_id):
    logger.info('Allow/Block Importer URL: <%s>', IMPORTER_URL)

    params = {
      'customerId': customer_id,
      'replace': True
    }

    multipartEncoder = MultipartEncoder(
      fields={'file': ('file', open(file_path, 'rb'), 'text/csv')}
    )

    multipartEncoderMonitor = MultipartEncoderMonitor(multipartEncoder, callback)

    headers = get_headers()
    headers['Content-Type'] = multipartEncoder.content_type

    response = requests.post(
        IMPORTER_URL,
        data = multipartEncoderMonitor,
        params = params,
        headers = headers,
        timeout=MAIL_PIC_RESPONSE_TIMEOUT
    )
    response.raise_for_status()

    responseAsJson = response.json()
    successful_count = responseAsJson['successful_count']
    error_entries = responseAsJson['error_entries']

    logger.info("successful count: {0}, error entries: {1}".format(successful_count, error_entries))

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(description = 'Upload Allow/Block list for customer')
    parser.add_argument('--customer_id', required = True, type = str, help = 'The customer ID for which to import Allow/Block lists')
    parser.add_argument('--file', required = True, type = str, help = 'The CSV file to upload')
    parser.add_argument('--replace', action = 'store_true', help = 'Replaces existing allow/block entries')

    args = parser.parse_args()

    upload_allow_block_lists(args.file, args.customer_id)
