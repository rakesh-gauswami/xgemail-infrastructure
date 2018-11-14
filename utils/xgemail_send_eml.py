#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

__author__ = 'sophos-email-dev-burlington@sophos.com'

"""
Allows sending eml files through the different Sophos Email environments.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import argparse
import email
import os
import random
import smtplib
import string
import sys

HEADER_SUBJECT = 'subject'
HEADER_DATE = 'date'
HEADER_MESSAGE_ID = 'message-id'

RANDOM_STRING_LENGTH = 10

SMTP_PORT = 25

DIRECTION_INBOUND = 'inbound'
DIRECTION_OUTBOUND = 'outbound'

def get_server(region, env, direction=DIRECTION_INBOUND):
    if direction == DIRECTION_INBOUND:
        return 'mx-01-{0}.{1}.hydra.sophos.com'.format(region, env)
    elif direction == DIRECTION_OUTBOUND:
        return 'relay-{0}.{1}.hydra.sophos.com'.format(region, env)
    else:
        raise Exception('Unable to retrieve server for environment <{0}> and direction <{1}>'.format(env, direction))

def get_random_string(size = RANDOM_STRING_LENGTH, chars = string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for unused in range(size))

def read_file(filename):
    if not filename or not os.path.isfile(filename):
        raise IOError('File not found: <{0}>'.format(filename))

    with open(filename) as f:
        return f.read()

def maybe_update_message(orig_message_as_string, subject, generate_message_id, remove_date):
    message = email.message_from_string(orig_message_as_string)

    if subject:
        if message.has_key(HEADER_SUBJECT):
            message.replace_header(HEADER_SUBJECT, subject)
        else:
            message.add_header(HEADER_SUBJECT, subject)

    if generate_message_id:
        random_local_part = get_random_string()
        random_domain = get_random_string()
        generated_message_id = '<{0}@{1}.com>'.format(random_local_part, random_domain)

        if message.has_key(HEADER_MESSAGE_ID):
            message.replace_header(HEADER_MESSAGE_ID, generated_message_id)
        else:
            message.add_header(HEADER_MESSAGE_ID, generated_message_id)

    if remove_date:
        if message.has_key(HEADER_DATE):
            message.__delitem__(HEADER_DATE)

    return message

def send_message(message, server, sender, recipients, requested_read_receipt, spoof_ip):
    smtp = None
    try:
        rcpt_options = []
        if requested_read_receipt:
            rcpt_options.append('NOTIFY=SUCCESS')

        smtp = smtplib.SMTP(server, SMTP_PORT)
        if spoof_ip:
            smtp.docmd('XCLIENT', 'ADDR={0}'.format(spoof_ip))

        smtp.sendmail(sender, recipients, message.as_string(), mail_options = [], rcpt_options = rcpt_options)
        print 'Message successfully sent.'
    except Exception as ex:
        print 'Failure: unable to send email: %s' % (ex)
    finally:
        if smtp != None:
            smtp.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = 'Send an email through Xgemail environment')
    parser.add_argument('sender', metavar='sender', type = str, help = 'The envelope sender address')
    parser.add_argument('recipients', metavar='recipients', nargs='+', type = str, help = 'The envelope recipient address(es)')
    parser.add_argument('eml', metavar='eml', type = str, help = 'The local email file to be sent (in EML format)')
    parser.add_argument('--emailstosend', default = 1, help = 'the number of emails to send using sender and recipient')
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'DEV3', 'QA', 'PROD','INF'], help = 'the region to send the email to (default: DEV)')
    parser.add_argument('--direction', default = DIRECTION_INBOUND, choices=[DIRECTION_INBOUND, DIRECTION_OUTBOUND], help = 'the email direction (default: inbound)')
    parser.add_argument('--keepmessageid', dest='keepmessageid', action = 'store_true', help = 'Do not generate a new Message-ID before sending the email')
    parser.add_argument('--keepdate', dest='keepdate', action = 'store_true', help = 'Keep the original date in the eml file (if exists)')
    parser.add_argument('--readreceipt', dest='readreceipt', action = 'store_true', help = 'Request a read receipt')
    parser.add_argument('--region', default = 'eu-central-1', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'the region to send the email to (default: eu-central-1)')
    parser.add_argument('--subject', help = 'Subject of the email')
    parser.add_argument('--spoofip', default = None, type = str, help = 'Allows you to spoof the sender address (if XCLIENT configured correctly)')

    args = parser.parse_args()

    sender = args.sender
    recipients = args.recipients
    eml_file = args.eml
    spoof_ip = args.spoofip

    emails_to_send = int(args.emailstosend)
    if emails_to_send <= 0:
        parser.error("emailstosend must at least be 1")

    subject = args.subject
    generate_message_id = not args.keepmessageid
    remove_date = not args.keepdate
    region = args.region
    env = args.env
    requested_read_receipt = args.readreceipt
    direction = args.direction

    message_as_string = read_file(eml_file)
    server = get_server(region, env.lower(), direction)

    print
    print 'Sending email:'
    print '-------------'
    print 'EML file:\t\t{0}'.format(eml_file)
    print 'Sender:\t\t\t{0}'.format(sender)
    print 'Recipient(s):\t\t{0}'.format(recipients)
    print 'Server:\t\t\t{0}'.format(server)
    print 'Direction:\t\t{0}'.format(direction)
    print 'Environment:\t\t{0}'.format(env)
    print 'Region:\t\t\t{0}'.format(region)
    print 'Generate Message-ID:\t{0}'.format(generate_message_id)
    print 'Remove Date header:\t{0}'.format(remove_date)
    print 'Requested read receipt:\t{0}'.format(requested_read_receipt)
    print 'Nr of emails to send:\t{0}'.format(emails_to_send)
    if subject:
        print 'Subject:\t\t{0}'.format(subject)
    if spoof_ip:
        print 'Spoof IP:\t\t{0}'.format(spoof_ip)
    print '-------------'

    for i in range(1, emails_to_send + 1):
        message = maybe_update_message(
            message_as_string,
            subject,
            generate_message_id,
            remove_date
        )

        if emails_to_send > 1:
            print 'Sending email {0}:'.format(i),

        send_message(
            message,
            server,
            sender,
            recipients,
            requested_read_receipt,
            spoof_ip
        )
