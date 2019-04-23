"""
AWS Lambda Function that is triggered from Kinesis Firehose
to transform log messages.

Copyright 2019, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

from __future__ import print_function

import json
import base64
import logging
import re


logger = logging.getLogger()
logger.setLevel(logging.INFO)

patterns = {
    'drop': '(Unknown feature flag)'
}

# Alternative Method
# drop_patterns = [
#     'Unknown feature flag'
# ]


def transform_records():
    """
    Transform each log
    """
    pass


def transform_microservice_log():
    """
    Transform each Microservice log
    """
    pass


def transform_lambda_log():
    """
    Transform each Lambda Function log
    """
    pass


def process_records(records):
    """
    Process each log from a batch of logs
    """
    for record in records:
        raw_data = base64.b64decode(record['data'])
        data = json.loads(raw_data)
        record_id = record['recordId']
        message = data['message']

        # Alternative method
        # for dp in drop_patterns:
        #     if dp in message:
        #         yield {
        #             'result': 'Dropped',
        #             'recordId': record_id
        #         }

        drop_pattern = re.compile(patterns['drop'])
        drop_match = drop_pattern.search(message)
        if drop_match:
            yield {
                'result': 'Dropped',
                'recordId': record_id
            }
        else:
            yield {
                'data': base64.b64encode(json.dumps(data)),
                'result': 'Ok',
                'recordId': record_id
            }


def firehose_transformation_handler(event, context):
    """
    Main Lambda Handler
    """
    records = list(process_records(event['records']))

    logger.info('Successfully processed {} of {} records.'.format(len(records), len(event['records'])))

    return {'records': records}
