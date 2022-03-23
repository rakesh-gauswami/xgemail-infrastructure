"""
AWS Lambda Function that is triggered from Kinesis Firehose
to transform log messages.

Copyright 2021, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.

Description:
This lambda function parses logs before they are sent to logzio and
drops any logs that match the defined drop patterns.

"""

import gzip
import json
import base64
import logging
import io
import os

logger = logging.getLogger()
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO').strip()
DEPLOYMENT_ENVIRONMENT = os.getenv('DEPLOYMENT_ENVIRONMENT').strip()


def transformLogEvent(log_event,acct,loggrp,logstrm, region, account):
    """
    Transform each log event.
    """
    sourcetype="aws:cloudwatchlogs"
    return_message = '{"@timestamp": ' + str(log_event['timestamp']) + ',"logGroup": "' + loggrp + '"'
    return_message = return_message + ',"application_name":"' + loggrp.split('/')[3]  + '"'
    return_message = return_message + ',"sourcetype":"' + sourcetype  + '"'
    return_message = return_message + ',"owner":"' + acct  + '"'
    return_message = return_message + ',"account":"' + account  + '"'
    return_message = return_message + ',"region":"' + region  + '"'
    return_message = return_message + ',"logStream":"' + logstrm  + '"'
    return_message = return_message + ',"tag":"sophos.xgemail.o365.' + loggrp.split('/')[3]  + '"'
    return_message = return_message + ',"message": ' + json.dumps(log_event['message']) + '}'

    return return_message + '\n'


def process_records(records, region):
    """
    Process each log from a batch of logs
    """
    for record in records:
        record_id = record['recordId']
        payload = base64.b64decode(record['data'])
        striodata = io.BytesIO(payload)
        with gzip.GzipFile(fileobj=striodata, mode='r') as f:
            try:
                data = json.loads(f.read())
                logger.debug("Decompressed data: {}".format(data))
                if data['messageType'] == 'CONTROL_MESSAGE':
                    yield {
                        'result': 'Dropped',
                        'recordId': record_id
                    }
                elif data['messageType'] == 'DATA_MESSAGE':
                    data = ''.join([transformLogEvent(e,data['owner'],data['logGroup'],data['logStream'],region,DEPLOYMENT_ENVIRONMENT) for e in data['logEvents']])
                    data = base64.b64encode(data.encode('utf-8')).decode()

                    yield {
                        'data': data,
                        'result': 'Ok',
                        'recordId': record_id
                    }
                else:
                    yield {
                        'result': 'ProcessingFailed',
                        'recordId': record_id
                    }
            except OSError:
                data = json.loads(payload)
                logger.debug("Decoded data: {}".format(data))

                yield {
                    'data': base64.b64encode(payload).decode('utf-8'),
                    'result': 'Ok',
                    'recordId': record_id
                }


def firehose_transformation_lambda_handler(event, context):
    """
    Iterates over the provided log events
    """
    records = list(process_records(event['records'], event['region']))

    logger.info('Successfully processed {} records.'.format(len(event['records'])))

    return {'records': records}
