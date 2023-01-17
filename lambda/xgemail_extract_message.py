import boto3
import struct
import gzip
import io
import time

SCHEMA_VERSION = 20170224
MSG_MAGIC_NUMBER = b'\0SOPHMSG'
MESSAGE_FILE_EXTENSION = ".MESSAGE"
NONCE_LENGTH = 0
session = boto3.Session()
s3 = boto3.resource('s3')


def athena_query(client, events):
    query_string = "SELECT message_path FROM series_datalake.telemetry_email_telemetry where queue_id = '" + events["PostfixQueueId"] + "' and direction = '" + events["Direction"] + "' and region = '" + events["Region"] + "'"
    response = client.start_query_execution(
        QueryString=query_string,
        ResultConfiguration={
            'OutputLocation': 's3://aws-athena-query-results-202058678495-eu-central-1/'
        }
    )
    return response


def get_message_path(events, max_execution=5):
    client = session.client('athena', region_name='eu-central-1')
    execution = athena_query(client, events)
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
                message_path = response['ResultSet']['Rows'][1]['Data'][0]['VarCharValue']
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


def send_email(message_path, events, message):
    client = session.client('ses', region_name='eu-central-1')
    response = client.send_raw_email(
        Source='sophos_message_extractor@sophos-message-extractor.net',
        Destinations=[
            'SophosMailOps@sophos.com'
        ],
        RawMessage={
            'Data': "From: sophos_message_extractor@sophos-message-extractor.net\nTo: SophosMailOps@sophos.com\nSubject: Sophos Email Message Extracted (contains an attachment)\nMIME-Version: 1.0\nContent-type: Multipart/Mixed; boundary=\"NextPart\"\n\n--NextPart\nContent-Type: text/html\n\nThe attached email was downloaded and deserialized from S3 path: " + message_path + ".\n\n--NextPart\nContent-Type: text/html;\nContent-Disposition: attachment; filename=\"" + events["PostfixQueueId"] + ".eml\"\n\n" + message + "\n\n--NextPart--"
        }
    )
    return response


def extract_message_handler(events, context):
    if events["Direction"] == "INBOUND":
        bucket = "private-cloud-prod-" + events["Region"] + "-cloudemail-xgemail-submit"
    elif events["Direction"] == "OUTBOUND":
        bucket = "private-cloud-prod-" + events["Region"] + "-cloudemail-xgemail-cust-submit"
    else:
        raise Exception("Message direction not set correctly.")
    bucket = s3.Bucket(bucket)
    message_path = get_message_path(events)
    message = bucket.Object(message_path)
    message_body = message.get()['Body'].read()
    return send_email(message_path, events, deserialize(message_body))
