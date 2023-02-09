import boto3
import gzip
import io
import json
import logging
import struct
import time
from botocore.exceptions import ClientError

print('Loading function')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SCHEMA_VERSION = 20170224
MSG_MAGIC_NUMBER = b'\0SOPHMSG'
MESSAGE_FILE_EXTENSION = ".MESSAGE"
NONCE_LENGTH = 0
recipients = ["SophosMailOps@sophos.com"]
session = boto3.Session()
s3 = boto3.resource('s3')


def athena_query(client, event):
    query_string = "SELECT message_path FROM series_datalake.telemetry_email_telemetry where queue_id = '" + event["PostfixQueueId"] + "' and direction = '" + event["Direction"] + "' and region = '" + event["Region"] + "'"
    response = client.start_query_execution(
        QueryString=query_string,
        ResultConfiguration={
            'OutputLocation': 's3://aws-athena-query-results-202058678495-eu-central-1/'
        }
    )
    return response


def get_message_path(event, max_execution=5):
    client = session.client('athena', region_name='eu-central-1')
    execution = athena_query(client, event)
    execution_id = execution['QueryExecutionId']
    state = 'RUNNING'

    while max_execution > 0 and state in ['RUNNING', 'QUEUED']:
        max_execution = max_execution - 1
        response = client.get_query_execution(QueryExecutionId=execution_id)

        if 'QueryExecution' in response and \
                'Status' in response['QueryExecution'] and \
                'State' in response['QueryExecution']['Status']:
            state = response['QueryExecution']['Status']['State']
            if state == 'FAILED':
                return False
            elif state == 'SUCCEEDED':
                try:
                    query_results = client.get_query_results(QueryExecutionId=execution_id)
                    logger.info("Athena query results. {}".format(query_results))
                except ClientError as e:
                    logger.exception("Unable to get query results. {}".format(e))
                    return False
                try:
                    message_path = query_results['ResultSet']['Rows'][1]['Data'][0]['VarCharValue'] + ".MESSAGE"
                except IndexError:
                    logger.exception("No message found in Athena.")
                    return False
                else:
                    logger.info("Message path : {}".format(message_path))
                    return message_path
                
        time.sleep(60)
    
    return False


def unzip_data(data):
    decompressed_bytes = None

    data_bytesio = io.BytesIO(data)

    try:
        decompressed_file = gzip.GzipFile(fileobj=data_bytesio, mode='rb')

        try:
            decompressed_bytes = decompressed_file.read()
        finally:
            decompressed_file.close()
    finally:
        data_bytesio.close()

    return decompressed_bytes


# Read and verify actual magic number matches with expected magic number
# 64 bit magic number
def is_correct_file_format(formatted_magic_bytes, expected_magic_number):
    actual_magic_number = formatted_magic_bytes.decode('ascii')
    if actual_magic_number != expected_magic_number:
        return False
    return True


# Read and verify nonce length - 32 bit nonce length
# since in V1 we don't encrypt data
def is_unencrypted_data(formatted_nonce_length_bytes):
    actual_nonce_length = struct.unpack('!I', formatted_nonce_length_bytes)[0]
    if actual_nonce_length != NONCE_LENGTH:
        return False
    return True


# rest of the bytes are gzipped data (metadata/message)
def get_decompressed_object_bytes(formatted_object_bytes):
    return unzip_data(
        formatted_object_bytes
    )


# Read and verify message magic number
def is_message_file(formatted_s3_msg_bytes):
    return is_correct_file_format(
        formatted_s3_msg_bytes,
        MSG_MAGIC_NUMBER
    )


# Accepts formatted email stream downloaded from S3 which has zipped email
# verifies if it is a right type file by magic number and if yes then
# returns unzipped email binary
def get_message_binary(formatted_s3_message):
    # total length of the magic_bytes (8) + version (8) + nonce (4) = 20
    return get_decompressed_object_bytes(
        formatted_s3_message[20:len(formatted_s3_message)]
    )


def deserialize(message_body):
    deserialized_content = get_message_binary(message_body).decode("utf-8")
    return deserialized_content


def send_email(message_path, recipients, event, message):
    client = session.client('ses', region_name='eu-central-1')
    response = client.send_raw_email(
        Source='sophos_message_extractor@sophos-message-extractor.net',
        Destinations=[
            recipients
        ],
        RawMessage={
            'Data': "From: sophos_message_extractor@sophos-message-extractor.net\nTo: " + recipients + "\nSubject: Sophos Email Message Extracted (contains an attachment)\nMIME-Version: 1.0\nContent-type: Multipart/Mixed; boundary=\"NextPart\"\n\n--NextPart\nContent-Type: text/html\n\nThe attached email was downloaded and deserialized from S3 path: " + message_path + ".\n\n--NextPart\nContent-Type: text/html;\nContent-Disposition: attachment; filename=\"" + event["PostfixQueueId"] + ".eml\"\n\n" + message + "\n\n--NextPart--"
        }
    )
    return response


def extract_message_handler(event, context):
    logger.info("Received event: {}".format(json.dumps(event)))
    logger.info("Log stream name: {}".format(context.log_stream_name))
    logger.info("Log group name: {}".format(context.log_group_name))
    logger.info("Request ID: {}".format(context.aws_request_id))
    logger.info("Mem. limits(MB): {}".format(context.memory_limit_in_mb))

    if event["Direction"] == "INBOUND":
        bucket = "private-cloud-prod-" + event["Region"] + "-cloudemail-xgemail-submit"
    elif event["Direction"] == "OUTBOUND":
        bucket = "private-cloud-prod-" + event["Region"] + "-cloudemail-xgemail-cust-submit"
    else:
        raise Exception("Message direction not set correctly.")
    bucket = s3.Bucket(bucket)
    message_path = get_message_path(event)
    if message_path:
        # Check for Sophos owned domains and quit since access is not permitted
        sophos_domains = ["sophos.com", "sophos.at", "sophos.it", "sophos.co.jp", "sophos.com.au", "sophos.co.nz", "sophos.de", "sophos.fr", "sophos.fi", "sophose.se"]
        if any(x in message_path for x in sophos_domains):
            logger.error("Quitting due to Sophos domain detected in message.")
            return "Extraction of Sophos owned domains is not permitted"
        else:
            message = bucket.Object(message_path)
            message_body = message.get()['Body'].read()
            if event["CcEmail"]:
                recipients.append(event["CcEmail"])
            response = send_email(message_path, recipients, event, deserialize(message_body))
            logger.info("===FINISHED WITH SUCCESS===.")
            return response
    else:
        logger.info("===FINISHED WITH FAILURE===.")
        return "No message found"
