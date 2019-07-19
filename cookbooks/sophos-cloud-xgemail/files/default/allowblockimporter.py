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
import os
import pip
import requests
import sys

try:
    from requests_toolbelt import MultipartEncoder
except ImportError:
    pip.main(['install', 'requests-toolbelt'])
    from requests_toolbelt import MultipartEncoder

try:
    from prettytable import PrettyTable
except ImportError:
    pip.main(['install', 'PrettyTable'])
    from prettytable import PrettyTable

# Constants
MAX_LINE_LENGTH = 61
MAX_CUSTOMER_ENTRIES = 30000
MAX_USER_ENTRIES = 10000
MAX_FILE_SIZE = 9500
MAIL_PIC_RESPONSE_TIMEOUT = 120
HEADER_LINE = 'entry, action, aliases\n'
FAILED_FILES_PATH = '/tmp/allow-block-import-failed.csv'
ERROR_ENTRIES_PATH = '/tmp/allow-block-errors.txt'
EMTPY_CSV_FILE_PATH = '/tmp/allow_block_empty.csv'

class Colors:
    """
    Colors used when printing messages
    """
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    HEADER = '\033[95m'
    ENDC = '\033[0m'

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
        response_as_json = self.response.json()
        if 'error_entries' in response_as_json:
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
    with open(file_name, 'w') as f:
        f.write(content + '\n')
    return file_name

def write_error_file(all_errors):
    """
    Writes a tabular file listing all the entries that could not be imported.
    """
    t = PrettyTable(['Entry', 'Error'])
    t.align = 'l'

    all_entries = set()

    for cur_entry in all_errors:
        entry = 'ENTERPRISE' if not cur_entry['address'] else cur_entry['address']
        error = cur_entry['input_parser_error_code']

        if entry + error in all_entries:
            continue
        all_entries.add(entry + error)

        t.add_row([entry, error])
    with open(ERROR_ENTRIES_PATH, 'w') as write_file:
        write_file.write(t.get_string())

def write_failed_files(failed_files):
    """
    Writes a file containing a combination of all files that failed to be uploaded.
    Returns the path to the file.
    """
    entries = {}
    for cur_file in failed_files:
        with open (cur_file, 'r') as failed_file:
            for line in failed_file.readlines()[1:]:
                key = ','.join(line.split(',')[0:2]).strip()
                if not key:
                    continue
                values = line.split(',')[2:]
                if not key in entries:
                    entries[key] = set()
                for value in values:
                    entries[key].add(value.strip())
    with open(FAILED_FILES_PATH, 'w') as write_file:
        write_file.write('entry, action, aliases\n')
        for key, value in entries.iteritems():
            write_file.write(key + ', ' + ', '.join(value) + '\n')

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

def import_csv(main_file, customer_id, import_url, region, env):
    """
    Imports the provided allow/block file for the given customer
    """
    all_results = []
    all_files = create_csv_files_with_max_size(main_file)
    files_already_uploaded = 0

    print_colorized('Uploading file {}'.format(main_file), Colors.HEADER)
    for cur_file in all_files:
        all_results.append(upload(import_url, cur_file, customer_id, False, region, env))
        files_already_uploaded += 1
        sys.stdout.write('{:6.2f}% uploaded\r'.format(float(files_already_uploaded)/float(len(all_files)) * 100))
        sys.stdout.flush()
    print

    failures = 0
    successful = 0
    all_errors = []
    failed_files = []
    for result in all_results:
        if not result.is_successful():
            failed_files.append(result.file_name)
            continue
        successful += result.get_successful()
        if result.has_errors():
            errors = result.get_errors()
            all_errors.extend(errors)
            failures += len(errors)

    indentation = max(len(str(successful)), len(str(failures)))

    print_errors()

    print_colorized(
        '[{}] entries imported successfully'.format(str(successful).rjust(indentation)),
        Colors.GREEN if successful > 0 else Colors.YELLOW
    )
    if len(failed_files) > 0:
        write_failed_files(failed_files)
        print_colorized(
            '[{}] files failed to be uploaded. Failure file written to: {}'.format(
                len(failed_files),
                FAILED_FILES_PATH
            ),
            Colors.YELLOW
        )
    if (failures > 0):
        error_file_path = write_error_file(all_errors)
        print_colorized(
            '[{}] entries failed to import. Report written to: {}'.format(
                str(failures).rjust(indentation),
                ERROR_ENTRIES_PATH
            ),
            Colors.YELLOW
        )

def determine_invalid_rows(main_file):
    """
    Determines any invalid rows from the main CSV file.
    Returns True if any invalid rows found, False otherwise
    """
    print_colorized('{0} WARNING {0}'.format('#'*26), Colors.HEADER)
    print_colorized('Maximum entries for customer allow/block entries:\t{}'.format(MAX_CUSTOMER_ENTRIES), Colors.HEADER)
    print_colorized('Maximum entries for user allow/block entries:\t\t{}'.format(MAX_USER_ENTRIES), Colors.HEADER)
    print_colorized('{}'.format('#'*MAX_LINE_LENGTH), Colors.HEADER)
    print

    with open(main_file, 'r') as f:
        line_number = 0
        nr_of_invalid_entries = 0

        for line in f.readlines():
            line_number += 1
            tokens = line.split(',')
            entries = len(tokens) - 2
            if tokens[0].lower() == 'enterprise':
                if entries > MAX_CUSTOMER_ENTRIES:
                    print_colorized(
                        'Customer allow/block entry {} exeeds maximum number of entries ({}): {}'.format(
                            line_number,
                            MAX_CUSTOMER_ENTRIES,
                            entries
                        ),
                        Colors.YELLOW
                    )
                    nr_of_invalid_entries += 1
            elif entries > MAX_USER_ENTRIES:
                print_colorized(
                    'User allow/block entry {} ({}) exeeds maximum number of entries ({}): {}'.format(
                        line_number,
                        tokens[0],
                        MAX_USER_ENTRIES,
                        entries
                    ),
                    Colors.YELLOW
                )
                nr_of_invalid_entries += 1
        if nr_of_invalid_entries == 0:
            print_colorized(
                'All {} entries are within the above defined limits'.format(line_number - 1),
                Colors.GREEN
            )
            return False
        print_colorized(
            'Found a total of {}/{} entries that exceed the above defined limits'.format(
                nr_of_invalid_entries,
                line_number - 1
            ),
            Colors.YELLOW
        )
        return True

def delete_all(import_url, customer_id, region, env):
    """
    Removes all allow/block entries for the provided customer
    """
    with open(EMTPY_CSV_FILE_PATH, 'a+'):
        result = upload(import_url, EMTPY_CSV_FILE_PATH, customer_id, True, region, env)
        if result.is_successful():
            print_colorized(
                'Successfully removed all customer-level allow/block entries',
                Colors.GREEN
            )
            return
        print_colorized(
            'Error while attempting to remove all customer-level allow/block entries. Status code: {}'.format(
                result.get_status_code()
            ),
            Colors.RED
        )

def print_colorized(text, color):
    """
    Prints colorized text to console
    """
    if color == Colors.YELLOW:
        print color + 'WARNING: ' + text + Colors.ENDC
    elif color == Colors.GREEN:
        print color + 'SUCCESS: ' + text + Colors.ENDC
    elif color == Colors.RED:
        print color + 'ERROR:   ' + text + Colors.ENDC
    else:
        print color + text + Colors.ENDC

def cleanup(main_file):
    """
    Cleans up any temporary files that were created during import process
    """
    os.system('rm -f {}.*'.format(FAILED_FILES_PATH))
    os.system('rm -f {}.*'.format(ERROR_ENTRIES_PATH))
    os.system('rm -f {}.*'.format(main_file))
    os.system('rm -f {}'.format(EMTPY_CSV_FILE_PATH))

def print_errors():
    if not os.path.exists(ERROR_ENTRIES_PATH):
        print
        print_colorized(
            'Unable to show errors from previous run because file {} does not exist'.format(
                ERROR_ENTRIES_PATH
            ),
            Colors.YELLOW
        )
        print
        return
    with open(ERROR_ENTRIES_PATH, 'r') as f:
        print f.read()

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(description = 'Upload Allow/Block list for customer')
    parser.add_argument('--customer_id', required = True, type = str, help = 'The customer ID for which to import Allow/Block lists')
    parser.add_argument('--force', action = 'store_true', help = 'Imports allow/block list entries even if they exeed the maximum number of allowed entries')
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
    group.add_argument('--retry', dest = 'retry', action = 'store_true', help = 'Retry previously failed upload attempt')
    group.add_argument('--errors', dest = 'errors', action = 'store_true', help = 'Show the errors from the previous run')

    args = parser.parse_args()

    import_url = 'https://mail-cloudstation-{}.{}.hydra.sophos.com/mail/api/xgemail/allow-block/import'.format(args.region, args.env)

    try:
        if args.retry:
            if not os.path.exists(FAILED_FILES_PATH):
                print
                print_colorized(
                    'Unable to retry previously failed attempt because file {} does not exist'.format(
                        FAILED_FILES_PATH
                    ),
                    Colors.YELLOW
                )
                print
                sys.exit(1)
            import_csv(FAILED_FILES_PATH, args.customer_id, import_url, args.region, args.env)
            sys.exit(0)

        if args.errors:
            print_errors()
            sys.exit(0)

        if args.delete_all:
            print_colorized(
                'Deleting all customer-level allow/block entries'.format(
                    FAILED_FILES_PATH
                ),
                Colors.HEADER
            )
            delete_all(import_url, args.customer_id, args.region, args.env)
            sys.exit(0)

        has_invalid_entries = determine_invalid_rows(args.file)

        if has_invalid_entries and not args.force:
            print_colorized(
                'Aborted import of allow/block due to invalid entries. Use --force to import anyways',
                Colors.RED
            )
            sys.exit(1)

        import_csv(args.file, args.customer_id, import_url, args.region, args.env)
    finally:
        cleanup(args.file)
