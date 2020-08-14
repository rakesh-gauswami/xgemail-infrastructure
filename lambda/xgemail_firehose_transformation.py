"""
AWS Lambda Function that is triggered from Kinesis Firehose
to transform log messages.

Copyright 2019, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.

Description:
This lambda function parses logs before they are sent to logzio and
drops any logs that match the defined drop patterns.

"""

import json
import base64
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DROP_PATTERNS = [
    'Unknown feature flag',
    'Missing value for <Authentication-Results> header',
    'REPORT RequestId:',
    'START RequestId:',
    'END RequestId:'
]

def firehose_transformation_handler(event, context):
    """
    Iterates over the provided log events and drops any logs
    that match any of the patterns defined in DROP_PATTERNS
    """
    output = []

    for record in event['records']:
        record_id = record['recordId']
        payload = base64.b64decode(record['data'])
        data = json.loads(payload)
        message = data['message']
        logger.debug('Record ID {} for {} message.'.format(record_id, message))

        output_record = {
            'recordId': record_id,
            'result': 'Ok',
            'data': base64.b64encode(payload)
        }
        for drop_pattern in DROP_PATTERNS:
            logger.debug('Dropping Record Id {}'.format(record_id))
            if drop_pattern in message:
                output_record = {
                    'result': 'Dropped',
                    'recordId': record_id
                }
                break
        output.append(output_record)

    logger.debug('Successfully processed {} records.'.format(len(event['records'])))
    return {'records': output}
