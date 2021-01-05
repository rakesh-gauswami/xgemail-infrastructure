#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Test ansible_modules_aws.s3_object.
"""

moto_import_failed = True

try:

    from moto import mock_s3
    from moto import mock_kms

    moto_import_failed = False

except:
    pass

# Import test module FIRST to make sure there are no dependencies.

import sophos.aws

from sophos.aws_kms import KMSManager
from sophos.aws_s3 import S3ObjectManager

import unittest
import os

class S3ObjectManagerSublcass(unittest.TestCase):

    def _setup_create_aws_client(self):
        self._aws_helper = sophos.aws.AwsHelper(session=sophos.aws.AwsSession(self._params['aws_profile'],
                                                                        self._params['aws_region']).create())

        self._s3_client = self._aws_helper.add_client("s3", region=self._params['aws_region'])
        self._kms_client = self._aws_helper.add_client("kms", region=self._params['aws_region'])

    def _setup_create_object_manager(self):
        self._s3_manager = S3ObjectManager(aws_profile=self._params['aws_profile'],
                                           aws_region=self._params['aws_region'],
                                           bucket=self._params['bucket'],
                                           sse=self._params['sse'],
                                           sse_key_id=self._params['sse_key_id'] if 'sse_key_id' in self._params else None)

        return self._s3_manager

    def _setup_create_kms_manager(self):
        self._kms_manager = KMSManager(aws_profile=self._params['aws_profile'],
                                       aws_region=self._params['aws_region'])

        return self._kms_manager

    def setUp(self):

        if hasattr(self, '_params') is False:
            self._params = {}

        if self._params is None:
            self._params = {}
        if 'bucket' not in self._params:
            self._params['bucket'] = 'bucket_upload'
        if 'path' not in self._params:
            self._params['path'] = './my_file.txt'
        if 'object' not in self._params:
            self._params['object'] = '/test/my_file.txt'
        if 'aws_region' not in self._params:
            self._params['aws_region'] = 'us-west-2'
        if 'aws_profile' not in self._params:
            self._params.setdefault('aws_profile',None)
        if 'sse' not in self._params:
            self._params['sse'] = False

        self._mock = mock_s3()
        self._mock.start()

        self._mock_kms = mock_kms()
        self._mock_kms.start()

        self._setup_create_aws_client()

    def tearDown(self):
        self._s3_manager = None

        self._mock.stop()
        self._mock_kms.stop()

@unittest.skipIf(moto_import_failed is True, "Import of moto mocking library failed!")
class TestCase01(S3ObjectManagerSublcass):

    def _setup_create_bucket(self):
        self._bucket = self._s3_client.create_bucket(Bucket=self._params['bucket'],
                                      CreateBucketConfiguration=
                                      {'LocationConstraint': self._params['aws_region']})

    def _setup_create_local_file(self):
        with open(self._params['path'], "wb") as f:
            f.write("sample text")

    def _setup_delete_local_file(self):
        os.remove(self._params['path'])

    def setUp(self):
        super(TestCase01, self).setUp()

        self._setup_create_object_manager()
        self._setup_create_bucket()
        self._setup_create_local_file()

    def tearDown(self):
        self._setup_delete_local_file()

        self._s3_client.delete_object(Bucket=self._params['bucket'], Key=self._params['object'])
        self._s3_client.delete_bucket(Bucket=self._params['bucket'])

        super(TestCase01, self).tearDown()

    def runTest(self):
        self._s3_manager.upload(self._params['path'], self._params['object'])

        self._setup_delete_local_file()

        assert os.path.exists(self._params['path']) == 0

        self._s3_manager.download(self._params['path'], self._params['object'])

        assert os.path.exists(self._params['path']) == 1

@unittest.skipIf(moto_import_failed is True, "Import of moto mocking library failed!")
class TestCase02(S3ObjectManagerSublcass):

    def setUp(self):
        super(TestCase02, self).setUp()

    def tearDown(self):
        super(TestCase02, self).tearDown()

    def test_bucket_does_not_exist(self):
        with self.assertRaises(Exception):
            self._s3_manager.upload(self._params['path'], self._params['object'])

@unittest.skipIf(moto_import_failed is True, "Import of moto mocking library failed!")
class TestCase03(S3ObjectManagerSublcass):
    def test_invalid_params(self):
        with self.assertRaises(Exception):
            object = S3ObjectManager(aws_profile2='test')

        with self.assertRaises(Exception):
            object = KMSManager(aws_profile2='test')

@unittest.skipIf(moto_import_failed is True, "Import of moto mocking library failed!")
class TestCase04(TestCase01):
    def setUp(self):
        self._params = {}
        self._params['sse'] = True

        super(TestCase04, self).setUp()

        self._setup_create_kms_key()
        self._setup_create_object_manager()

    def tearDown(self):
        super(TestCase04, self).tearDown()

    def _setup_create_kms_key(self):
        result = self._kms_client.create_key(
                            Description='testcase03_test_key',
                            KeyUsage='ENCRYPT_DECRYPT')

        self._params['sse_key_id'] = result['KeyMetadata']['KeyId']

    def test_upload_kms_key_id(self):
        kms_args = self._s3_manager.upload(self._params['path'], self._params['object'])

        self.assertEqual(kms_args["SSEKMSKeyId"], self._params['sse_key_id'],"sse_key_id doesn't match!")

        self.assertEqual(kms_args["ServerSideEncryption"],"aws:kms","aws:kms was not specified!")

        self._setup_delete_local_file()

        assert os.path.exists(self._params['path']) == 0

        self._s3_manager.download(self._params['path'], self._params['object'])

        assert os.path.exists(self._params['path']) == 1

@unittest.skipIf(moto_import_failed is True, "Import of moto mocking library failed!")
class TestCase05(TestCase01):
    def setUp(self):
        self._params = {}
        self._params['sse'] = True

        super(TestCase05, self).setUp()

        self._setup_create_kms_key()
        self._setup_create_object_manager()

        self._kms_key_alias_name = 'testcase04_key_alias'

        self._setup_create_kms_alias()

        self._params['sse_key_id'] = self._setup_create_kms_manager().get_key_id_from_alias(self._kms_key_alias_name)

    def tearDown(self):
        super(TestCase05, self).tearDown()

    def _setup_create_kms_key(self):
        result = self._kms_client.create_key(
            Description='testcase04_test_key',
            KeyUsage='ENCRYPT_DECRYPT')

        self._params['sse_key_id'] = result['KeyMetadata']['KeyId']

    def _setup_create_kms_alias(self):
        alias_name = 'alias/' + self._kms_key_alias_name

        self._kms_client.create_alias(AliasName=alias_name,
                                      TargetKeyId=self._params['sse_key_id'])

        self._params['sse_key_id'] = self._kms_key_alias_name

    def test_upload_kms_key_alias(self):
        kms_args = self._s3_manager.upload(self._params['path'], self._params['object'])

        self.assertEqual(kms_args["SSEKMSKeyId"], self._params['sse_key_id'], "sse_key_id doesn't match!")
        self.assertEqual(kms_args["ServerSideEncryption"], "aws:kms", "aws:kms was not specified!")

        self._setup_delete_local_file()
        assert os.path.exists(self._params['path']) == 0

        self._s3_manager.download(self._params['path'], self._params['object'])
        assert os.path.exists(self._params['path']) == 1

@unittest.skipIf(moto_import_failed is True, "Import of moto mocking library failed!")
class TestCase06(TestCase01):
    def setUp(self):
        self._params = {}
        self._params['sse'] = True

        super(TestCase06, self).setUp()

        self._setup_create_kms_key()
        self._setup_create_object_manager()

    def tearDown(self):
        super(TestCase06, self).tearDown()

    def _setup_create_kms_key(self):
        result = self._kms_client.create_key(
            Description='testcase03_test_key',
            KeyUsage='ENCRYPT_DECRYPT')

        self._params['sse_key_id'] = result['KeyMetadata']['KeyId']

    def test_upload_kms_key_id(self):
        kms_args = self._s3_manager.upload(self._params['path'], self._params['object'])

        self.assertEqual(kms_args["SSEKMSKeyId"], self._params['sse_key_id'], "sse_key_id doesn't match!")

        self.assertEqual(kms_args["ServerSideEncryption"], "aws:kms", "aws:kms was not specified!")

        self._setup_delete_local_file()

        assert os.path.exists(self._params['path']) == 0

        self._s3_manager.download(self._params['path'], self._params['object'])

        assert os.path.exists(self._params['path']) == 1

        self._s3_manager.delete(self._params['object'])

        with self.assertRaises(Exception):
          self._s3_client.download_file(self._params['path'], self._params['object'])


if __name__ == "__main__":
    unittest.main()
