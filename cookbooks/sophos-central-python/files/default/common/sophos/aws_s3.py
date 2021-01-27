#!/usr/bin/python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
This module provides functionality to manage S3 objects.
- S3ObjectManager: implements upload, download and delete
- IllegalArgumentError: exception derived from ValueError
"""

import sophos.aws

class S3ObjectManager:
    """
    A simple class used to manage S3 objects.

    Bucket needs to be created before using this implementation.
    """
    def __init__(self, **kwargs):
        """
        Reads the arguments specified in kwargs.

        :param kwargs (dict): aws_region,
                              aws_profile,
                              sse,
                              sse_key_id,
                              bucket
        :return None
        :raises TypeError: Unkown parameter specified or parameter is missing
        """
        if kwargs is None:
            raise TypeError('No parameter specified!')

        self._s3_client = None
        self._bucket_name = None
        self._object = None
        self._path = None
        self._sse_key_id = None

        for key, value in kwargs.iteritems():
            if key == 'aws_region':
                self._aws_region = value
            elif key == 'aws_profile':
                self._aws_profile = value
            elif key == 'sse':
                self._sse = value
            elif key == 'sse_key_id':
                self._sse_key_id = value
            elif key == 'bucket':
                self._bucket_name = value
            else:
                raise TypeError('Unknown parameter found: [%s]' % key)

        # The bucket need to be specified

        if self._bucket_name is None:
            raise TypeError('Parameter bucket is missing!')

        # create an AwsHelper object that handles sessions and clients
        # the internal session objects reflects aws profile and aws region
        self._aws_helper = sophos.aws.AwsHelper(session=sophos.aws.AwsSession(self._aws_profile, self._aws_region).create())

    def _get_extra_args_kms(self):
        extra_args = {}
        extra_args["SSEKMSKeyId"] = self._sse_key_id
        extra_args["ServerSideEncryption"] = "aws:kms"

        return extra_args

    def _create_aws_helper(self):
        return sophos.aws.AwsHelper(session=sophos.aws.AwsSession(self._aws_profile, self._aws_region).create())

    @property
    def s3_client(self):
        """
        Instantiates a boto3 S3 client object that connects to the S3 endpoint
        of a specific location specified by aws_region.

        :return: boto3 s3 client object
        """
        if self._s3_client is None:
            # retrieve the bucket origin location
            self._bucket_location = self.get_bucket_location()

            # finally, create the s3 client with the correct region
            self._s3_client = self._aws_helper.add_client("s3", region=self._bucket_location)


        return self._s3_client

    @property
    def is_sse(self):
        """
        A value of True encrypts the resulting object with the KMS master key id.
        :return: True/False
        """
        return self._sse

    def get_bucket_location(self):
        """
        The bucket location is needed by boto3 to construct the correct S3 endpoint url.
        :return: aws region specifier like (us-west-2, us-east-1, eu-west-1, ...)
        """
        return self._create_aws_helper().get_bucket_location(self._bucket_name)

    def upload(self, path, object):
        """
        Upload the file to S3
        :param path The local path of the file to upload to S3
        :param object The S3 object key used to store the contents of the file
        :return: None or kms parameter used to encrypt the file in S3 (if sse == True)
        """
        if self.is_sse is True:
            args_kms = self._get_extra_args_kms()

            self.s3_client.upload_file(path, self._bucket_name, object, args_kms)
            return args_kms
        else:
            self.s3_client.upload_file(path, self._bucket_name, object)
            return None

    def download(self, path, object):
        """
        Download the file from S3 to the local file system.
        :param path The local path of the file to store the contents of the S3 object
        :param object The key of the contents of the S3 object to download
        :return: None
        """
        self.s3_client.download_file(self._bucket_name, object, path)

    def delete(self, object):
        """
        Delete the file form S3.
        :param object The key of the S3 object to delete
        :return: None
        """
        self.s3_client.delete_object(Bucket=self._bucket_name, Key=object)
    
    def list (self,object):
        """
        List files recursively based on the prefix
        :param object The prefix or key to be used to start listing objects
        :return: list of files
        """
        return self.s3_client.list_objects(Bucket=self._bucket_name, Prefix=object, Marker=object)