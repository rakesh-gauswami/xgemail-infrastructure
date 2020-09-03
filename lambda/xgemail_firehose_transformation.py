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
    'User was created with null/empty key',
    'User key is blank. Flag evaluation will proceed, but the user will not be stored in LaunchDarkly',
    'Successfully initialized the consumer org.apache.kafka.clients.consumer.KafkaConsumer@',
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

        output_record = {
            'recordId': record_id,
            'result': 'Ok',
            'data': base64.b64encode(payload)
        }

        if data.get('message'):
            message = data['message']
            for drop_pattern in DROP_PATTERNS:
                logger.debug('drop_pattern {} message {}'.format(drop_pattern, message))
                if drop_pattern in message:
                    logger.debug('Dropping Record Id {}'.format(record_id))
                    output_record = {
                        'result': 'Dropped',
                        'recordId': record_id
                    }
                    break
        else:
            logger.debug('message field not present in data {}'.format(data))
        logger.debug('Record ID {} for {} message.'.format(record_id, message))

        output.append(output_record)

    logger.debug('Successfully processed {} records.'.format(len(event['records'])))
    return {'records': output}
