"""
 Copyright 2019, Sophos Limited. All rights reserved.

 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
 Sophos Limited and Sophos Group.  All other product and company
 names mentioned are trademarks or registered trademarks of their
 respective owners.
"""

import os
import requests
import logging
import random
import smart_open
import sys
import boto3
import urllib.error
import urllib.parse
import urllib.request

TOKEN = os.getenv('TOKEN').strip()
TYPE = os.getenv('TYPE').strip()
DEPLOYMENT_ENVIRONMENT = os.getenv('DEPLOYMENT_ENVIRONMENT').strip()
PREFIX = os.getenv('PREFIX', 'logs').strip()

MAX_ROWS = 10000
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO').strip()
logger = logging.getLogger('log_shipper')

OFFLINE_MODE = False


def send_to_logz(log):
    logger.debug("Sending {} logs".format(len(log)))
    if (TYPE == 'json' or TYPE == 'lambda'):
        url = "https://listener-eu.logz.io:8071?token={}&type={}".format(TOKEN, TYPE)
        logger.info("Sending to {}".format(url))
        if(OFFLINE_MODE):
            logger.debug("Sending data: {}".format(log))
        else:
            r = requests.post(
                url,
                data=bytes("\n".join(log), 'utf-8')
            )
            logger.info("Response: {}".format(r.status_code))
    else:
        url = "https://listener-eu.logz.io:8022/file_upload/{}/{}".format(TOKEN, TYPE)
        logger.info("Sending to {}".format(url))
        if(OFFLINE_MODE):
            logger.info("Sending data: {}".format(log))
        else:
            r = requests.post(
                url,
                data=bytes("\n".join(log), 'utf-8')
            )
            logger.info("Response: {}".format(r.status_code))


def parse_content(key, region):

    # Was unable to get s3v4 working with boto, with that enabled this conditional is unnecessary
    s3_host = None
    if region == 'eu-central-1':
        s3_host = 's3.eu-central-1.amazonaws.com'
    elif region == 'us-east-2':
        s3_host = 's3.us-east-2.amazonaws.com'

    transport_params = {}

    if s3_host is not None:
        transport_params['resource_kwargs'] = {
            'endpoint_url': "http://{}".format(s3_host)
        }

    with smart_open.open(key, 'r', transport_params=transport_params) as fin:
        num_excluded = 0
        num_skipped_sampling = 0
        log = []
        count = 0
        for line in fin:
            count += 1
            logger.debug("line {}: {}".format(count, line))
            log.append(line)
            if count % MAX_ROWS == 0:
                logger.debug("Count: {}, log: {}".format(count, log))
                send_to_logz(log)
                log = []
        logger.debug("count: {}, log: {}".format(count, log))
        send_to_logz(log)

        if(DEPLOYMENT_ENVIRONMENT == 'dev' or OFFLINE_MODE):
            logger.warn("Sent {} log lines, excluded {} log lines due to exclusion rules and skipped {} log lines for sampling".format(count, num_excluded, num_skipped_sampling))


def log_shipping_lambda_handler(event, context):
    logger.setLevel(logging.getLevelName(LOG_LEVEL))
    logger.debug("Number of Records: {}".format(len(event['Records'])))
    for record in event['Records']:
        logger.info("Capturing event JSON which triggered this lambda: {}".format(event))
        bucket, key, region = extract_s3_meta_details(record)
        parse_content(key="s3://{}/{}".format(bucket,key), region=region)


def extract_s3_meta_details(record):
    bucket = record['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(record['s3']['object']['key'])
    logger.info("Sending {}/{} to logz.io".format(bucket, key))
    region = record['awsRegion']
    return bucket, key, region


def setup_offline_logging():
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    logger.setLevel(logging.INFO)

    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    ch.setFormatter(formatter)

    logger.addHandler(ch)


if __name__ == "__main__":
    OFFLINE_MODE = True
    DEPLOYMENT_ENVIRONMENT = 'OFFLINE'
    setup_offline_logging()

    parse_content(sys.argv[1], 'OFFLINE')
