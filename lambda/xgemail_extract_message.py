import boto3
import struct
import gzip
import io

SCHEMA_VERSION = 20170224
MSG_MAGIC_NUMBER = b'\0SOPHMSG'
MESSAGE_FILE_EXTENSION = ".MESSAGE"
NONCE_LENGTH = 0


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


def extract_message_handler(events, context):
    s3 = boto3.resource('s3')
    if events["Direction"] == "INBOUND":
        bucket = "private-cloud-prod-" + events["Region"] + "-cloudemail-xgemail-submit"
    elif events["Direction"] == "OUTBOUND":
        bucket = "private-cloud-prod-" + events["Region"] + "-cloudemail-xgemail-cust-submit"
    bucket = s3.Bucket(bucket)
    message = bucket.Object(events["Key"])
    message_body = message.get()['Body'].read()

    return deserialize(message_body)