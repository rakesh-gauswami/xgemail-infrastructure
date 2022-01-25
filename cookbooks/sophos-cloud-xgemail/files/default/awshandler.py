#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This script is responsible for communicating with AWS.

import os
import boto3
import json
from botocore.exceptions import ClientError
from botocore.credentials import RefreshableCredentials
from botocore.session import get_session
from boto3 import Session
from uuid import uuid4


class AwsHandler(object):
    def __init__(self, aws_region):
        self.aws_region = aws_region
        self.role_arn = os.environ.get('STATION_ACCOUNT_ROLE_ARN')
        if self.role_arn == 'none':
            self.session = boto3.session.Session(region_name=self.aws_region)
        else:
            if self.session is None:
                self.session_name = uuid4().hex
                self.session = Session()
            self.session_credentials = RefreshableCredentials.create_from_metadata(
                metadata=self.refresh_session(), refresh_using=self.refresh_session, method="sts-assume-role"
            )
            s = get_session()
            s._credentials = self.session_credentials
            s.get_config_variable("region")
            s.set_config_variable("region", self.aws_region)
            self.session = Session(botocore_session=s)
        self.s3_client = self.session.client("s3")
        self.sqs_client = self.session.client("sqs")
        self.sns_client = self.session.client("sns")
        self.firehose_client = self.session.client('firehose')

    def refresh_session(self):
        credentials = self.session.client("sts").assume_role(
            RoleArn=self.role_arn, RoleSessionName=self.session_name
        )["Credentials"]
        return dict(
            access_key=credentials["AccessKeyId"],
            secret_key=credentials["SecretAccessKey"],
            token=credentials["SessionToken"],
            expiry_time=credentials["Expiration"].isoformat(),
        )

    # puts data into S3 bucket
    def upload_data_in_s3(self, bucket, key, data, expires, encryption):
        params = {
            'Body': data,
            'Expires': expires,
            'Bucket': bucket,
            'Key': key,
            'ServerSideEncryption': encryption
        }
        return self.s3_client.put_object(**params)

    # put a message in SQS for an accepted email
    def add_to_sqs(self, queue_url, message_body):
        return self.sqs_client.send_message(
            QueueUrl=queue_url,
            MessageBody=message_body)

    # publishes data to sns topic
    def publish_to_sns_topic(self, topic_arn, message_body, message_attributes={}):
        return self.sns_client.publish(
            TargetArn=topic_arn,
            Message=message_body,
            MessageAttributes=message_attributes
        )

    def download_message_from_s3(self, bucket, sqs_message):
        # remove leading slash and append proper data type
        sanitized_path = sqs_message.message_path.strip("/") + ".MESSAGE"

        return self.download_data_from_s3(bucket, sanitized_path)

    def download_metadata_from_s3(self, bucket, sqs_message):
        # remove leading slash and append proper data type
        sanitized_path = sqs_message.message_path.strip("/") + ".METADATA"

        return self.download_data_from_s3(bucket, sanitized_path)

    # gets data as a binary array from S3
    def download_data_from_s3(self, bucket, path):
        response = self.s3_client.get_object(
            Bucket=bucket,
            Key=path
        )
        body = response["Body"]

        # body is of type StreamingBody which is a file-like
        # object. read() reads the entire body.
        return body.read()

    def create_sqs(self, queue_name, retention_period, timeout, sns_topic_arn):
        response = self.sqs_client.create_queue(QueueName=queue_name)
        sqs_queue_url = response['QueueUrl']
        response = self.sqs_client.get_queue_attributes(QueueUrl=sqs_queue_url, AttributeNames=['QueueArn'])
        sqs_queue_arn = response['Attributes']['QueueArn']
        dead_letter_queue_name = queue_name + '-DLQ'
        dead_letter_queue_url = self.sqs_client.create_queue(QueueName=dead_letter_queue_name)['QueueUrl']
        dead_letter_queue_arn = self.sqs_client.get_queue_attributes(QueueUrl=dead_letter_queue_url, AttributeNames=['QueueArn'])['Attributes']['QueueArn']
        sqs_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": "*"},
                    "Action": "sqs:SendMessage",
                    "Resource": sqs_queue_arn,
                    "Condition": {
                        "ArnEquals": {
                            "aws:SourceArn": sns_topic_arn
                        }
                    }
                }
            ]
        }
        sqs_redrive_policy = {
            'deadLetterTargetArn': dead_letter_queue_arn,
            'maxReceiveCount': 5
        }
        sqs_attributes = {
            'MessageRetentionPeriod': retention_period,
            'Policy': json.dumps(sqs_policy),
            'RedrivePolicy': json.dumps(sqs_redrive_policy),
            'VisibilityTimeout': timeout
        }
        self.sqs_client.set_queue_attributes(QueueUrl=sqs_queue_url, Attributes=sqs_attributes)
        return sqs_queue_url

    def subscribe_sqs(self, sns_policy_arn, sqs_url):
        queue_arn = self.sqs_client.get_queue_attributes(
            QueueUrl=sqs_url,
            AttributeNames=['QueueArn']
        )['Attributes']['QueueArn']

        sns_client = boto3.client('sns', region_name=self.aws_region)
        return sns_client.subscribe(
            TopicArn=sns_policy_arn,
            Protocol="sqs",
            Endpoint=queue_arn
        )

    def get_sqs_url(self, queue_name):
        return self.sqs_client.get_queue_url(
            QueueName=queue_name
        )['QueueUrl']

    def receive_sqs_messages(self, queue_url, attributes, message_attributes,
                             max_messages, visibility_timeout, wait_time_in_sec):
        return self.sqs_client.receive_message(
            QueueUrl=queue_url,
            AttributeNames=attributes,
            MessageAttributeNames=message_attributes,
            MaxNumberOfMessages=max_messages,
            VisibilityTimeout=visibility_timeout,
            WaitTimeSeconds=wait_time_in_sec
        )

    def delete_message(self, queue_url, receipt_handle):
        self.sqs_client.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=receipt_handle
        )

    def list_objects(self, bucket, path_prefix):
        s3_list = []
        paginator = self.s3_client.get_paginator("list_objects_v2")
        page_iterator = paginator.paginate(
            Bucket=bucket,
            Prefix=path_prefix)
        for page in page_iterator:
            if "Contents" in page:
                for key in page["Contents"]:
                    file_key = key["Key"]
                    if file_key.endswith("/"):
                        continue
                    s3_list.append(file_key)

        return s3_list

    def key_exists(self, bucket, key, path_prefix):
        paginator = self.s3_client.get_paginator("list_objects_v2")
        page_iterator = paginator.paginate(
            Bucket=bucket,
            Prefix=path_prefix)
        for page in page_iterator:
            if "Contents" in page:
                for obj in page["Contents"]:
                    if key == obj["Key"]:
                        return True

        return False

    # safely check's key exists in s3 or not.
    # Doesn't throw exception if key doesn't exist, returns boolean value.
    def s3_key_exists(self, bucket_name, key_name):
        try:
            response = self.s3_client.head_object(Bucket=bucket_name, Key=key_name)
            return response['ResponseMetadata']['HTTPStatusCode'] == 200
        except ClientError as ce:
            # Not found
            return int(ce.response['Error']['Code']) != 404

    def list_filtered_objects(self, bucket, path_prefix, filter):
        s3_list = []
        paginator = self.s3_client.get_paginator("list_objects_v2")
        page_iterator = paginator.paginate(
            Bucket=bucket,
            Prefix=path_prefix)
        for page in page_iterator:
            if "Contents" in page:
                for key in page["Contents"]:
                    file_key = key["Key"]
                    if file_key.endswith(filter):
                        s3_list.append(file_key)

        return s3_list

    # puts data into S3 bucket
    def upload_data_in_s3_without_expiration(self, bucket, key, data, encryption):
        params = {
            'Body': data,
            'Bucket': bucket,
            'Key': key,
            'ServerSideEncryption': encryption
        }
        return self.s3_client.put_object(**params)

    def put_data_to_kinesis_delivery_stream(self, stream_name, data):
        put_response = self.firehose_client.put_record(
            DeliveryStreamName=stream_name,
            Record={
                'Data': json.dumps(data)
            }
        )
        return put_response

    # deletes key in S3 bucket
    def delete_object_in_s3(self, bucket, key):
        params = {
            'Bucket': bucket,
            'Key': key
        }
        return self.s3_client.delete_object(**params)
