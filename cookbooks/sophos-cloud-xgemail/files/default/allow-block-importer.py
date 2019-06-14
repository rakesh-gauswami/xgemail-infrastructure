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
MAIL_PIC_RESPONSE_TIMEOUT = 120
MAIL_PIC_API_AUTH = 'xgemail-eu-west-1-mail'
CONNECTIONS_BUCKET = 'cloud-dev-connections'
MAX_FILE_SIZE = 10000

EMTPY_CSV_FILE_PATH = '/tmp/allow_block_empty.csv'

# Logging to syslog setup
logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger('allow-block-importer')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
handler.formatter = formatter
logger.addHandler(handler)

ACCOUNT = 'dev'

class ApiResult:
    def __init__(self, file_name, response):
        self.file_name = file_name
        self.response = response

    def __str__(self):
        return str(self.__class__) + ": " + str(self.__dict__)

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
    """
    Splits the file provided as parameter into smaller files based on
    the MAX_FILE_SIZE constant.
    """
    all_files = set()
    with open(file_path, 'r') as f:
        file_nr = 0
        for line in f.readlines():
            new_file_path = '{0}.{1}'.format(file_path, file_nr)
            all_files.add(new_file_path)

            if (os.path.exists(new_file_path)):
                cur_size = os.stat(new_file_path).st_size
                if cur_size + len(line) >= MAX_FILE_SIZE:
                    file_nr += 1
                    new_file_path = '{0}.{1}'.format(file_path, file_nr)

            with open(new_file_path, 'a+') as dest_file:
                dest_file.write(line)
    return all_files

def upload(file_path, customer_id, replace):
    """
    Uploads the file under the provided file path for the given customer
    """
    logger.info(
        'Importing %s for customer %s. Replace existing entries: %s',
        file_path,
        customer_id,
        replace
    )

    params = {
      'customerId': customer_id,
      'replace': replace
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
    return ApiResult(file_path, response)

def import_csv(main_file, customer_id, replace):
    """
    Imports the provided allow/block file for the given customer
    """
    all_results = []
    for cur_file in split_files(main_file):
        all_results.append(
            upload(cur_file, customer_id, replace)
        )

    failure_file = '{0}_failed'.format(main_file)
    failures = 0
    for result in all_results:
        if result.response == 200:
            continue
        with open(result.file_name, 'r') as read_file:
            with open(failure_file, 'a+') as write_file:
                for line in read_file:
                    failures += 1
                    write_file.write(line)
    if failures > 0:
        logger.warn('Total failures: {0}'.format(failures))
        logger.warn('Failure entries written to {0}'.format(failure_file))

def delete_all(customer_id):
    """
    Removes all allow/block entries for the provided customer
    """
    with open(EMTPY_CSV_FILE_PATH, 'a+'):
        upload(EMTPY_CSV_FILE_PATH, customer_id, True)

def cleanup(main_file):
    """
    Cleans up any temporary files that were created during import process
    """
    logger.info('Cleaning up temporary files for {0}'.format(main_file))
    os.system('rm -f {0}.*'.format(main_file))
    os.system('rm -f {0}'.format(EMTPY_CSV_FILE_PATH))

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(description = 'Upload Allow/Block list for customer')
    parser.add_argument('--customer_id', required = True, type = str, help = 'The customer ID for which to import Allow/Block lists')
    parser.add_argument('--replace', action = 'store_true', help = 'Replaces existing allow/block entries')

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--file', type = str, help = 'The CSV file containing Allow/Block entries to be imported')
    group.add_argument('--delete-all', dest = 'delete_all', action = 'store_true', help = 'Removes all currently stored Allow/Block entries for the given customer')

    args = parser.parse_args()

    if args.delete_all:
        logger.info("Deleting all allow/block entries for customer")
        delete_all(args.customer_id)
    else:
        import_csv(args.file, args.customer_id, args.replace)
    cleanup(args.file)
