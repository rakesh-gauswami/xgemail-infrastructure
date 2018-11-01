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
# Run this script on any instance that has access to the Message History Delivery DLQ under analysis.
#

import argparse
import boto3
import json
import os
import sys
import uuid

DLQ = {
    'DEV': {
        'eu-west-1': 'https://sqs.eu-west-1.amazonaws.com/750199083801/vpc-e4c06c81-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ',
        'eu-central-1': 'https://sqs.eu-central-1.amazonaws.com/750199083801/vpc-465fe72f-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ'
    },
    'QA': {
        'eu-west-1': 'https://sqs.eu-west-1.amazonaws.com/382702281923/vpc-b427a4d1-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ',
        'eu-central-1': 'https://sqs.eu-central-1.amazonaws.com/382702281923/vpc-11109d78-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ',
        'us-west-2': 'https://sqs.us-west-2.amazonaws.com/382702281923/vpc-854ef5e0-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ',
        'us-east-2': 'https://sqs.us-east-2.amazonaws.com/382702281923/vpc-9e87adf7-Xgemail_MessageHistoryEvent_Delivery_SNS_Listener-DLQ'
    },
    'PROD': {
        'eu-west-1': 'https://sqs.eu-west-1.amazonaws.com/202058678495/vpc-05a30b60-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ',
        'eu-central-1': 'https://sqs.eu-central-1.amazonaws.com/202058678495/vpc-fe129c97-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ',
        'us-west-2': 'https://sqs.us-west-2.amazonaws.com/202058678495/vpc-8fb208ea-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ',
        'us-east-2': 'https://sqs.us-east-2.amazonaws.com/202058678495/vpc-61d5ec08-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ'
    }
}

def delete_messages(entries):
    resp = sqs_client.delete_message_batch(
        QueueUrl=queue_url, Entries=entries
    )

    if len(resp['Successful']) != len(entries):
        raise RuntimeError(
            "Failed to delete messages: entries={0} resp={1}".format(entries, resp)
        )

def get_messages_from_queue(queue_url, should_delete_messages, region):
    sqs_client = boto3.client('sqs', region_name=region)

    msgs_retrieved = 0

    while True:
        resp = sqs_client.receive_message(
            QueueUrl=queue_url,
            AttributeNames=['All'],
            MaxNumberOfMessages=10
        )
        try:
            yield resp['Messages']
        except KeyError:
            print 'All {0} messages downloaded'.format(msgs_retrieved)
            return

        entries = [
            {'Id': msg['MessageId'], 'ReceiptHandle': msg['ReceiptHandle']}
            for msg in resp['Messages']
        ]

        if should_delete_messages:
            delete_messages(entries)
        msgs_retrieved += len(entries)

def write_document(directory, document):
    filename = uuid.uuid4()
    full_path = '{0}/{1}.json'.format(directory, filename)

    print 'Writing file {0}'.format(full_path)

    with open(full_path, 'w') as the_file:
        the_file.write(document)

def analyse(directory):
    print 'reading documents from directory {0}'.format(directory)

    total = 0
    results = {'quarantine_summary': [], 'null_queue_ids': [], 'rest': []}

    for filename in os.listdir(directory):
        with open('{0}/{1}'.format(directory, filename), 'r') as the_file:
            total += 1
            doc = json.loads(the_file.read())

            if not 'message_path' in doc:
                doc = json.loads(doc['Message'])

            msg_path = doc['message_path']
            if msg_path and 'quarantine-summary' in msg_path:
                results['quarantine_summary'].append(doc)
                continue

            recipient_address = doc['recipient_address']
            next_queue_log = doc['next_queue_log']

            if not msg_path and not recipient_address and not next_queue_log:
                results['null_queue_ids'].append(doc)
            else:
                results['rest'].append(doc)

    print 'Total documents analysed:       {0}'.format(total)
    print 'Total quarantine_summary:       {0}'.format(len(results['quarantine_summary']))
    print 'Total null queue_id messages:   {0}'.format(len(results['null_queue_ids']))
    print 'Total rest:                     {0}'.format(len(results['rest']))

    nr_of_examples_to_show = 5

    print
    print '-'*20

    if len(results['quarantine_summary']) > 0:
        print 'Example of quarantine summary jobs:'
        i = 0
        for job in results['quarantine_summary']:
            if i >= nr_of_examples_to_show:
                break
            print json.dumps(job)
            i += 1
        print
        print '-'*20

    if len(results['null_queue_ids']) > 0:
        print 'Example of null jobs:'
        i = 0
        for job in results['null_queue_ids']:
            if i >= nr_of_examples_to_show:
                break
            print json.dumps(job)
            i += 1
        print
        print '-'*20

    if len(results['rest']) > 0:
        print 'Examples of remaining jobs:'
        i = 0
        for job in results['rest']:
            if i >= nr_of_examples_to_show:
                break
            print json.dumps(job)
            i += 1
        print
        print '-'*20

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = 'Send an email through Xgemail environment')
    parser.add_argument('--region', default = 'eu-west-1', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'the region to send the email to (default: eu-west-1)')
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'DEV3', 'QA', 'PROD','INF'], help = 'the region to send the email to (default: DEV)')
    parser.add_argument('--retrieve', help = 'retrieve messages from DLQ and write to the provided directory')
    parser.add_argument('--read', help = 'read previously downloaded jobs from the provided directory')

    args = parser.parse_args()
    path = os.getcwd()

    region = args.region
    env = args.env

    if args.retrieve:
        queue_url = DLQ[env][region]
        local_directory = args.retrieve
        directory = '{0}/{1}'.format(path, local_directory)

        if not os.path.exists(directory):
            os.makedirs(directory)

        for messages in get_messages_from_queue(queue_url, False, region):
            for message in messages:
                write_document(directory, message['Body'])
    elif args.read:
        local_directory = args.read
        directory = '{0}/{1}'.format(path, local_directory)
        analyse(directory)
    else:
        parser.print_help(sys.stderr)
        sys.exit(1)
