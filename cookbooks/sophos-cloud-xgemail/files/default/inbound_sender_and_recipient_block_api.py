#!/usr/bin/env python
# -*- encoding: utf-8 -*-
# Copyright 2021, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This script can be used to retrieve existing blocked/blacklisted entries,
# block new addresses or unblock existing entries.
#
# Run this script on a internet-submit (e.g. CloudEmail:internet-submit). Make
# sure you are in the appropriate AWS environment.

import sys
sys.path.append("/opt/sophos/xgemail/utils")

import base64
import boto3
import json
import requests
import sys
import urllib3
import os
import re
import pip
import gziputils
import string
import time

import argparse
import json
import logging
from logging.handlers import SysLogHandler
from email.utils import parseaddr
from awshandler import AwsHandler
from botocore.exceptions import ClientError

try:
    from prettytable import PrettyTable
except ImportError:
    pip.main(['install', 'PrettyTable'])
    from prettytable import PrettyTable

import argparse
import pip
import formatterutils

# logging to syslog setup
logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger('inbound_sender_and_recipient_block_api')
logger.setLevel(logging.DEBUG)
syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
syslog_handler.formatter = formatter
logger.addHandler(syslog_handler)

#Constants
DOMAIN_NAME_REGEX_PATTERN = "[a-zA-Z0-9][-a-zA-Z0-9]*(\\.[-a-zA-Z0-9]+)*\\.[a-zA-Z]{2,}"
EMAIL_ADDRESS_REGEX_PATTERN = "(([^<>()\[\]\\.,;:\s@\"]+(\.[^<>()\[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))";


POLICY_BUCKET_NAME = 'private-cloud-{}-{}-cloudemail-xgemail-policy'
INBOUND_BLOCK_CONFIG_PATH = 'config/inbound-relay-control/block-list/'
INBOUND_BLOCK_CONFIG_FILE_NAME = 'inbound_block_list.CONFIG'
INBOUND_BLOCK_CONFIG_FILE_PATH = INBOUND_BLOCK_CONFIG_PATH + 'inbound_block_list.CONFIG'
INBOUND_BLOCK_CONFIG_AUDIT_LOGS = '/audit-logs/'

MAGIC_NUMBER = b'\0SOPHCONFIG'
SCHEMA_VERSION = 20210107
S3_ENCRYPTION_ALGORITHM = 'AES256'

# Nonce length is 0 because we are using AES256 algo for encrypting data along with magic byte
NONCE_LENGTH = 0

DEFAULT_INBOUND_BLOCK_LIST_TEMPLATE = {
    "inbound_block_list": {
        "email_addresses" : {

        },
        "domains": {

        }
    }
}

def get_parsed_args(parser):
    parser.add_argument(
        '--region',
        dest = 'region',
        required = True,
        choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'],
        help = 'the AWS region'
    )
    parser.add_argument(
        '--env',
        dest = 'env',
        required = True,
        choices=['DEV', 'DEV3', 'QA', 'PROD','INF'],
        help = 'The AWS environment'
    )
    parser.add_argument(
        '--event-type',
        dest = 'event_type',
        required = True,
        choices=['BLOCK_ENVELOPE_SENDER', 'BLOCK_SENDER', 'BLOCK_RECIPIENT'],
        help = 'smtp transaction event at which validation is required'
    )
    parser.add_argument('--block', dest = "block", action = 'store_true', help = 'Block given email address or domain')
    parser.add_argument('--unblock', dest = "unblock", action = 'store_true', help = 'Unblock given email address or domain')
    parser.add_argument(
        '--email-address',
        dest = 'email_address',
        default = None,
        help = 'email address to be blocked/unblocked'
    )
    parser.add_argument(
        '--domain',
        dest = 'domain_name',
        default = None,
        help = 'domain name to be blocked/unblocked'
    )
    parser.add_argument(
        '--get-all',
        dest = 'get_all',
        action='store_true',
        help = 'retrieve list of currently blacklisted entries'
    )

    return parser.parse_args()


# Uses the Regex pattern we use in Jilter to match and validate email address
def validate_email_address(address):
    match_object = re.search(EMAIL_ADDRESS_REGEX_PATTERN, address)
    if match_object is None or not match_object:
        raise ValueError("invalid email address [{0}] is provided".format(address))
    return match_object.group()


def validate_domain(domain_address):
    match_object = re.search(DOMAIN_NAME_REGEX_PATTERN, domain_address)
    if match_object is None or not match_object:
        raise ValueError("invalid domain name [{0}] is provided".format(domain_address))
    return match_object.group()


def validate_args(args):
    if args.block is False and args.unblock is False:
        parser.error("Any one of the arguments [--block, --unblock] is required")

    if args.email_address is None and args.domain_name is None:
        parser.error("Please provide any of [ --email-address, --domain ] attribute")
    if args.email_address is not None:
        validate_email_address(args.email_address)
    if args.domain_name is not None:
        validate_domain(args.domain_name)

# serialization and deserialization methods


def is_valid_format(magic_bytes):
    """
     Confirms that the provided file is of the correct file format
    """
    return formatterutils.is_correct_file_format(magic_bytes, MAGIC_NUMBER)


def get_binary(formatted_file):
    """
    Verifies that the magic number matches, decompresses the file and
    returns the content as a string
    """
    magic_number_length = len(MAGIC_NUMBER)
    nonce_length_start_idx = 8 + magic_number_length
    nonce_length_end_idx = 12 + magic_number_length

    if not is_valid_format(formatted_file[0:len(MAGIC_NUMBER)]):
        raise ValueError("File format error: invalid magic bytes!")

    if not formatterutils.is_unencypted_data(formatted_file[nonce_length_start_idx:nonce_length_end_idx]):
        raise ValueError("File format error: invalid nonce length bytes!")

    return formatterutils.get_decompressed_object_bytes(
        formatted_file[nonce_length_end_idx:len(formatted_file)]
    )



def read_config_data(bucket_name):
    try:
        #verify if file exists in S3
        does_exist_in_s3 = awshandler.s3_key_exists(
            bucket_name,
            INBOUND_BLOCK_CONFIG_PATH + INBOUND_BLOCK_CONFIG_FILE_NAME
        )
        if does_exist_in_s3:
            logger.debug(
                "config file [{0}] exists in S3, downloading it"
                    .format(INBOUND_BLOCK_CONFIG_PATH + INBOUND_BLOCK_CONFIG_FILE_NAME)
            )
            serialized_content = awshandler.download_data_from_s3(
                bucket_name,
                INBOUND_BLOCK_CONFIG_PATH + INBOUND_BLOCK_CONFIG_FILE_NAME
            )

            deserialized_content = get_binary(serialized_content)
            return json.loads(deserialized_content)

        else:
            logger.info(
                "Config file doesn't exist in s3, creating default inbound block list file in [{0}] bucket at path [{1}]"
                .format(bucket_name,INBOUND_BLOCK_CONFIG_FILE_PATH)
            )
            upload_config_data(bucket_name,DEFAULT_INBOUND_BLOCK_LIST_TEMPLATE)
            return DEFAULT_INBOUND_BLOCK_LIST_TEMPLATE

    except (IOError, ClientError) as e:
        logger.error("Inbound block list config file: [{0}] does not exist or failed to read. error: [{1}]"
                     .format(INBOUND_BLOCK_CONFIG_FILE_PATH, e))
        raise Exception("Inbound block list config file: [{0}] does not exist or failed to read. error: [{1}]"
                        .format(INBOUND_BLOCK_CONFIG_FILE_PATH, e))


# Binary file format with Big Endian (Network) byte order except encryption
# Magic Bytes:  { '\0', 'S', 'O', 'P', 'H', 'C', 'O', 'N', 'F', 'I', 'G' }
# Version: 64-bit long based on date
# Nonce (IV) Length: 0
# Nonce (IV): randomly generated bytes to use with AES encryption
# Blob:	block list config data
def upload_config_data(bucket_name, config_object):
    compressed_data = gziputils.gzip_data(json.dumps(config_object))
    formatted_data = formatterutils.get_formatted_object(
        MAGIC_NUMBER,
        SCHEMA_VERSION,
        NONCE_LENGTH,
        compressed_data
    )

    awshandler.upload_data_in_s3_without_expiration(
        bucket_name,
        INBOUND_BLOCK_CONFIG_FILE_PATH,
        formatted_data,
        S3_ENCRYPTION_ALGORITHM
    )



def update_block_type_list(current_types, args):
    if args.event_type == 'BLOCK_ENVELOPE_SENDER' and 'BLOCK_ENVELOPE_SENDER' not in current_types:
        current_types.append('BLOCK_ENVELOPE_SENDER')
    if args.event_type == 'BLOCK_SENDER' and 'BLOCK_SENDER' not in current_types:
        current_types.append('BLOCK_SENDER')
    if args.event_type == 'BLOCK_RECIPIENT' and 'BLOCK_RECIPIENT' not in current_types:
        current_types.append('BLOCK_RECIPIENT')
    return current_types


def update_block_details(bucket_name, args):
    config_data = read_config_data(bucket_name)

    if args.email_address is not None:
        if config_data['inbound_block_list']['email_addresses'].has_key(args.email_address):
            email_config = config_data['inbound_block_list']['email_addresses'].get(args.email_address)
            config_data['inbound_block_list']['email_addresses'][args.email_address] = {
                "types": update_block_type_list(email_config["types"],args),
                "timestamp": int(time.time())
            }
        else:
            config_data['inbound_block_list']['email_addresses'][args.email_address] = {
                "types": [args.event_type],
                "timestamp": int(time.time())
            }

    if args.domain_name is not None:
        if config_data['inbound_block_list']["domains"].has_key(args.domain_name):
            domain_config = config_data['inbound_block_list']["domains"][args.domain_name]
            config_data['inbound_block_list']["domains"][args.domain_name] = {
                "types": update_block_type_list(domain_config["types"],args),
                "timestamp": int(time.time())
            }
        else:
            # Create new config object under domains parent key
            config_data['inbound_block_list']["domains"][args.domain_name] = {
                "types": [args.event_type],
                "timestamp": int(time.time())
            }
    return config_data


def update_unblock_details(bucket_name, args):
    config_data = read_config_data(bucket_name)
    print ("Bharat final Config data: ", config_data)

    if args.email_address is not None \
       and config_data['inbound_block_list']['email_addresses'].has_key(args.email_address):

        types = config_data['inbound_block_list']['email_addresses'][args.email_address]["types"]
        if args.event_type in types:
            types.remove(args.event_type)
        config_data['inbound_block_list']['email_addresses'][args.email_address] = {
            "types": types,
            "timestamp": int(time.time())
        }

    if args.domain_name is not None \
       and config_data['inbound_block_list']["domains"].has_key(args.domain_name):

        types = config_data['inbound_block_list']["domains"][args.domain_name]["types"]
        if args.event_type in types:
            types.remove(args.event_type)
        config_data['inbound_block_list']["domains"][args.domain_name] = {
            "types": types,
            "timestamp": int(time.time())
        }

    return config_data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = 'Block/unblock senders/recipient email address or domain for inbound mail flow')
    args = get_parsed_args(parser)
    validate_args(args)

    awshandler = AwsHandler(args.region)

    bucket_name = POLICY_BUCKET_NAME.format(string.lower(args.env), args.region)
    config_data = {}
    if args.block is True:
        config_data = update_block_details(bucket_name, args)
    if args.unblock is True:
        config_data = update_unblock_details(bucket_name, args)

    upload_config_data(bucket_name, config_data)