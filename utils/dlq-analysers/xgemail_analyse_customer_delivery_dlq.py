#!/usr/bin/env python
# -*- encoding: utf-8 -*-
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Downloads all messages from a Message History Delivery DLQ for further analysis
# This script was created to investigate messages landing in the DLQ as part of
# bug tickets XGE-7228 and XGE-7229.
#
# Run this script on any instance that has access to the Customer Delivery DLQ under analysis.
#

import argparse
import boto3
import json
import os
import sys
import uuid

DLQ = {
    'DEV': {
        'eu-west-1': 'https://sqs.eu-west-1.amazonaws.com/750199083801/vpc-e4c06c81-Xgemail_Customer_Delivery_SNS_Listener-DLQ'
    },
    'QA': {

    },
    'PROD': {
        'us-east-2': 'https://sqs.us-east-2.amazonaws.com/202058678495/vpc-61d5ec08-Xgemail_Customer_Delivery_SNS_Listener-DLQ',
        'us-west-2': 'https://sqs.us-west-2.amazonaws.com/202058678495/vpc-8fb208ea-Xgemail_Customer_Delivery_SNS_Listener-DLQ'
    }
}

results = {
    'mail_loop': {
        'delete': False,
        'messages': []
    },
    'quarant_summary': {
        'delete': False,
        'messages': []
    },
    'uncategorized': {
        'delete': False,
        'messages': []
    }
}

def delete_messages(sqs_client, queue_url, is_dry_run):
    for key, value in results.iteritems():
        if value['delete']:
            all_entries = [
                {'Id': msg['MessageId'], 'ReceiptHandle': msg['ReceiptHandle']}
                for msg in value['messages']
            ]

            if is_dry_run:
                print '[DRY RUN]: Removing {0} jobs from DLQ for category {1}'.format(len(all_entries), key)
                continue

            print 'Removing {0} jobs from DLQ for category {1}'.format(len(all_entries), key)

            max_entries = 10
            split_entries = [all_entries[x:x+max_entries] for x in range(0, len(all_entries), max_entries)]

            for entries in split_entries:
                resp = sqs_client.delete_message_batch(
                    QueueUrl=queue_url,
                    Entries=entries
                )

                if len(resp['Successful']) != len(entries):
                    print 'Failed to delete messages: entries={0} resp={1}'.format(entries, resp)

def get_messages_from_queue(sqs_client, queue_url, region):
    msgs_retrieved = 0

    while True:
        resp = sqs_client.receive_message(
            QueueUrl=queue_url,
            AttributeNames=['All'],
            MaxNumberOfMessages=10
        )
        try:
            yield resp['Messages']
            msgs_retrieved += len(resp['Messages'])
        except KeyError:
            print 'All {0} messages downloaded'.format(msgs_retrieved)
            return

def write_document(directory, document):
    filename = uuid.uuid4()
    full_path = '{0}/{1}.json'.format(directory, filename)

    print 'Writing file {0}'.format(full_path)

    json_to_write = json.loads(document['Body'])
    json_to_write['MessageId'] = document['MessageId']
    json_to_write['ReceiptHandle'] = document['ReceiptHandle']

    with open(full_path, 'w') as the_file:
        the_file.write(json.dumps(json_to_write))

def analyse(directory, results_to_print):
    print 'reading documents from directory {0}'.format(directory)

    total = 0
    sender_and_recipient_same = 0

    for filename in os.listdir(directory):
        with open('{0}/{1}'.format(directory, filename), 'r') as the_file:
            total += 1
            doc = json.loads(the_file.read())

            if 'Message' in doc:
                message = json.loads(doc['Message'])
            else:
                message = doc

            sender_domain = message['sender'].split('@')[1]
            recipients = message['mailboxes']

            found_record = False
            for recipient in recipients:
                recipient_domain = recipient.split('@')[1]
                if recipient_domain == sender_domain:
                    found_record = True
                    results['mail_loop']['messages'].append(doc)
                    break

            if message['submit_message_type'] == 'QUARANTINE_SUMMARY':
                results['quarant_summary']['messages'].append(doc)
                continue

            if not found_record:
                results['uncategorized']['messages'].append(doc)

    print 'Total documents analysed:\t{0}'.format(total)
    for key, value in results.iteritems():
        print 'Total {0}:\t\t{1}'.format(key, len(value['messages']))

    print
    print '-'*20
    for key, value in results.iteritems():
        if len(value['messages']) > 0:
            print '{0} example of {1}:'.format(results_to_print, key)
            i = 0
            for job in value['messages']:
                if i >= results_to_print:
                    break
                if 'Message' in job:
                    print job['Message']
                else:
                    print job
                i += 1
            print
            print '-'*20

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = 'Send an email through Xgemail environment')
    parser.add_argument('--region', default = 'eu-west-1', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'the region to send the email to (default: eu-west-1)')
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'DEV3', 'QA', 'PROD','INF'], help = 'the region to send the email to (default: DEV)')
    parser.add_argument('--retrieve', help = 'retrieve messages from DLQ and write to the provided directory')
    parser.add_argument('--analyse', help = 'analyse previously downloaded jobs from the provided directory')
    parser.add_argument('--dryrun', action='store_true', help = 'if provided, do not actually delete any messages from SQS')
    parser.add_argument('--results', default = 5, help = 'defines the number of results to print')

    args = parser.parse_args()
    path = os.getcwd()

    region = args.region
    env = args.env

    queue_url = DLQ[env][region]

    sqs_client = boto3.client('sqs', region_name=region)

    if args.retrieve:
        local_directory = args.retrieve
        directory = '{0}/{1}'.format(path, local_directory)

        if not os.path.exists(directory):
            os.makedirs(directory)

        for messages in get_messages_from_queue(sqs_client, queue_url, region):
            for message in messages:
                write_document(directory, message)
    elif args.analyse:
        local_directory = args.analyse
        directory = '{0}/{1}'.format(path, local_directory)
        analyse(directory, int(args.results))
        delete_messages(sqs_client, queue_url, args.dryrun)
    else:
        parser.print_help(sys.stderr)
        sys.exit(1)
