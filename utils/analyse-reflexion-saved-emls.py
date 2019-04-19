#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

__author__ = 'sophos-email-dev-burlington@sophos.com'

"""
Retrieves the stored messages from the Reflexion system rfx-asp.reflexion.net.
This script is mainly used in conjunction with the xgemail_send_eml.py script which
in general is the source of the emails that are analysed here.

Note: running this script requires root access to the rfx-asp.reflexion.net system.

Copyright 2019, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import argparse
import email
import fnmatch
import json
import os
import sys
import StringIO
import gzip

HEADER_MESSAGE_ID = 'message-id'
RFX_ASP_SERVER = 'rfx-asp.reflexion.net'
RFX_ASP_USER = 'root'
SAVED_SOURCES_DIRECTORY = '/remote-storage/src-msgs'
LOCAL_DIRECTORY = 'src-msgs'
LOCAL_DIRECTORY_EML = 'emls'
SMART_BANNER_ID = 'sophossmartbanner'

def cleanup_local_directories():
    """
    Cleans up the local directories
    """
    os.system('rm -rf {0}/*'.format(LOCAL_DIRECTORY))
    os.system('rm -rf {0}/*'.format(LOCAL_DIRECTORY_EML))

def download_all_files_from_rfx_asp():
    """
    Downloads all stored eml files from the rfx-asp.reflexion.net system
    """
    os.system(
        'rsync -avrz {0}@{1}:{2} .'.format(
            RFX_ASP_USER,
            RFX_ASP_SERVER,
            SAVED_SOURCES_DIRECTORY,
            LOCAL_DIRECTORY
        )
    )

def has_payload_smart_banner(payload):
    """
    Returns true if the smart banner is attached to the payload, false otherwise
    """
    if not payload:
        return False
    return SMART_BANNER_ID in payload

def analyse_files(report):
    """
    Analyse all files based on the provided JSON report
    """
    matches = []
    for root, dirnames, filenames in os.walk(LOCAL_DIRECTORY):
        for filename in fnmatch.filter(filenames, '*.gz'):
            matches.append(os.path.join(root, filename))

    successes = 0
    failures = 0
    failed = []
    succeeded = []
    for match in matches:
        compressed_file = StringIO.StringIO()
        with open(match, 'r') as r:
            compressed_file.write(r.read())

        # Set the file's current position to the beginning
        # of the file so that gzip.GzipFile can read
        # its contents from the top.
        compressed_file.seek(0)
        decompressed_file = gzip.GzipFile(fileobj=compressed_file, mode='rb').read()
        message = email.message_from_string(decompressed_file)
        message_id = message.get(HEADER_MESSAGE_ID)

        if message_id in report:
            sanitized_message_id = message_id.replace('<','').replace('>','')
            smart_banner_found = has_payload_smart_banner(decompressed_file)
            if message.is_multipart():
                for payload in message.get_payload():
                    if has_payload_smart_banner(payload.get_payload(decode=True)):
                        smart_banner_found = True
                        break
            else:
                if has_payload_smart_banner(message.get_payload(decode=True)):
                    smart_banner_found = True

            if smart_banner_found:
                successes += 1
                succeeded.append(sanitized_message_id)
                print 'Found a match WITH smartbanner attached: {0}'.format(message_id)
            else:
                failures += 1
                failed.append(sanitized_message_id)
                print 'Found a match WITHOUT smartbanner attached: {0}'.format(message_id)

            with open('{0}/{1}.eml'.format(LOCAL_DIRECTORY_EML, sanitized_message_id), 'w') as f:
                f.write(decompressed_file)
    total = len(report.keys())
    result = {
        'total': total,
        'success': successes,
        'failure': failures,
        'missing': (total - successes - failures),
        'succeeded': succeeded,
        'failed': failed
    }
    return result

if __name__ == "__main__":
    """
    Entry point to the script
    """
    parser = argparse.ArgumentParser(description = 'Retrieve and analyse emails delivered through Sophos Email')
    parser.add_argument('--report', metavar='report', type = str, help = 'The report containing the message ids for the messages to analyse', required = True)
    parser.add_argument('--skipdownload', action = 'store_true', help = 'Skips download of emails from rfx-asp')

    args = parser.parse_args()

    report_path = args.report

    with open(report_path, 'r') as f:
        report = json.loads(f.read())

    if not args.skipdownload:
        cleanup_local_directories()
        download_all_files_from_rfx_asp()

    print json.dumps(analyse_files(report), indent=4, sort_keys=True)
