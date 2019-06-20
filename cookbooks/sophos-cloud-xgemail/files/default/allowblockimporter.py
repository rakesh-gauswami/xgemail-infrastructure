#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Allows importing of arbitrarily large CSV files containing allow/block list
# entries for both customers and end-users.
#
# Both the regular as well as Reflexion-specific CSV format is supported.
#
# Copyright: Copyright (c) 1997-2019. All rights reserved.
# Company: Sophos Limited or one of its affiliates.

import argparse
import base64
import boto3
import csv
import json
import logging
import os
import pip
import requests
import sys

try:
    from requests_toolbelt import MultipartEncoder
except ImportError:
    pip.main(['install', 'requests-toolbelt'])
    from requests_toolbelt import MultipartEncoder

# Constants
MAX_FILE_SIZE = 9500
MAIL_PIC_RESPONSE_TIMEOUT = 120
HEADER_LINE = 'entry, action, aliases\n'
EMTPY_CSV_FILE_PATH = '/tmp/allow_block_empty.csv'

# Logging to syslog setup
logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger('allow-block-importer')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter(
    '[%(name)s] %(levelname)s %(message)s'
)
handler.formatter = formatter
logger.addHandler(handler)

class ApiResult:
    """
    Contains all necessary data provided by the API response
    """
    def __init__(self, file_name, response):
        self.file_name = file_name
        self.response = response

    def get_status_code(self):
        return self.response.status_code

    def is_successful(self):
        return self.get_status_code() in (200, 201)

    def get_successful(self):
        if not self.is_successful():
            return 0
        return self.response.json()['successful_count']

    def has_errors(self):
        response_as_json = self.response.json()
        return 'error_entries' in response_as_json and len(response_as_json['error_entries']) > 0

    def get_errors(self):
        if 'error_entries' in self.response.json():
            return response_as_json['error_entries']
        return []

    def __str__(self):
        return str(self.__class__) + ": " + str(self.__dict__)

def get_passphrase(region, env):
    """
    Retrieves the basic authentication from S3
    """
    s3 = boto3.client('s3')
    passphrase = s3.get_object(
        Bucket = 'cloud-{}-connections'.format(env.lower()),
        Key = 'xgemail-{}-mail'.format(region)
    )
    return base64.b64encode('mail:' + passphrase['Body'].read())

def write_new_file(file_name, content):
    """
    Writes the provided content to a new file under the provided path
    """
    logger.debug('Writing new file {}: \n{}'.format(file_name, content))
    with open(file_name, 'w') as f:
        f.write(content + '\n')
    return file_name

def create_csv_files_with_max_size(file_path):
    """
    Creates smaller CSV files with a max size of MAX_FILE_SIZE
    """
    all_files = set()
    with open(file_path, 'r') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        # skip header line
        next(csv_reader)

        new_file_content = HEADER_LINE
        cur_file = 0
        for row in csv_reader:
            if len(row) <= 2:
                # empty/invalid line
                continue
            new_file_content += '{},{}'.format(row[0], row[1])
            for cur_alias in row[2:]:
                cur_len = len(new_file_content)
                added_alias = ',{}'.format(cur_alias)

                if cur_len + len(added_alias) >= MAX_FILE_SIZE:
                    all_files.add(write_new_file('{}.{}'.format(file_path, cur_file), new_file_content))
                    cur_file += 1
                    new_file_content = '{}{},{}'.format(HEADER_LINE, row[0], row[1])
                new_file_content += added_alias
            new_file_content += '\n'
        all_files.add(write_new_file('{}.{}'.format(file_path, cur_file), new_file_content))
        return all_files

def upload(import_url, file_path, customer_id, replace, region, env):
    """
    Uploads the file under the provided file path for the given customer
    """
    params = {
      'customerId': customer_id,
      'replace': replace
    }

    multipartEncoder = MultipartEncoder(
      fields={'file': ('file', open(file_path, 'rb'), 'text/csv')}
    )

    headers = { 'Authorization': 'Basic ' + get_passphrase(region, env) }
    headers['Content-Type'] = multipartEncoder.content_type

    response = requests.post(
        import_url,
        data = multipartEncoder,
        params = params,
        headers = headers,
        timeout=MAIL_PIC_RESPONSE_TIMEOUT
    )
    return ApiResult(file_path, response)

def import_csv(main_file, customer_id, replace, import_url, region, env):
    """
    Imports the provided allow/block file for the given customer
    """
    all_results = []
    all_files = create_csv_files_with_max_size(main_file)
    files_already_uploaded = 0
    logger.info('Uploading {}'.format(main_file))
    for cur_file in all_files:
        all_results.append(upload(import_url, cur_file, customer_id, replace, region, env))
        files_already_uploaded += 1
        logger.info('{:.2f}% uploaded'.format(float(files_already_uploaded)/float(len(all_files)) * 100))

    failures = 0
    successful = 0
    all_errors = []
    failed_files = []
    for result in all_results:
        if not result.is_successful():
            logger.warn('Failed to upload file {}. Response code: {}'.format(result.file_name, result.get_status_code()))
            failed_files.append(result.file_name)
            continue
        logger.info("response: {}".format(result.response.json()))
        successful += result.get_successful()
        if result.has_errors():
            errors = result.get_errors()
            all_errors.append(errors)
            failures += len(errors)

    if len(all_errors) > 0:
        failure_file = '{}_failed'.format(main_file)
        with open(failure_file, 'w') as write_file:
            for line in all_errors:
                write_file.write(line + '\n')

    if len(failed_files) > 0:
        logger.warn('Files failed to upload:')
        for failed_file in failed_files:
            logger.warn('{}'.format(failed_file))

    logger.info('Total entries successfully imported: {}'.format(successful))
    logger.info('Total entries failed to be imported: {}'.format(failures))

    if (len(all_errors) > 0):
        logger.info('Failure entries written to {}'.format(failure_file))

def delete_all(import_url, customer_id, region, env):
    """
    Removes all allow/block entries for the provided customer
    """
    with open(EMTPY_CSV_FILE_PATH, 'a+'):
        upload(import_url, EMTPY_CSV_FILE_PATH, customer_id, True, region, env)

def cleanup(main_file):
    """
    Cleans up any temporary files that were created during import process
    """
    logger.debug('Cleaning up temporary files for {}'.format(main_file))
    os.system('rm -f {}.*'.format(main_file))
    os.system('rm -f {}'.format(EMTPY_CSV_FILE_PATH))

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(description = 'Upload Allow/Block list for customer')
    parser.add_argument('--customer_id', required = True, type = str, help = 'The customer ID for which to import Allow/Block lists')
    parser.add_argument('--replace', action = 'store_true', help = 'Replaces existing allow/block entries')
    parser.add_argument('-r', '--region', dest = 'region', default = 'eu-west-1',
        choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'],
        help = 'The region in which the customer resides (default: eu-west-1)'
    )
    parser.add_argument('-e', '--env', dest = 'env', default = 'PROD',
        choices=['DEV', 'DEV3', 'QA', 'PROD'],
        help = 'The environment in which the customer resides (default: PROD)'
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--file', type = str, help = 'The CSV file containing Allow/Block entries to be imported')
    group.add_argument('--delete-all', dest = 'delete_all', action = 'store_true',
        help = 'Removes all currently stored Allow/Block entries for the given customer'
    )

    args = parser.parse_args()

    import_url = 'https://mail-cloudstation-{}.{}.hydra.sophos.com/mail/api/xgemail/allow-block/import'.format(args.region, args.env)

    if args.delete_all:
        logger.info("Deleting all allow/block entries for customer")
        delete_all(import_url, args.customer_id, args.region, args.env)
        sys.exit(0)

    import_csv(args.file, args.customer_id, args.replace, import_url, args.region, args.env)
    cleanup(args.file)
