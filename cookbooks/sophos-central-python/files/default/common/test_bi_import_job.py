#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import boto3
import json
import mock
import moto
import unittest
from botocore.client import Config

from sophos.bi_import_job import import_bi_job


class TestBIImportJob(unittest.TestCase):
    region = 'eu-central-1'
    bucket_name = 'cloud-test-biexport-eu-central-1'
    job_run_id = 'RunId-2017-01-01-00-00-00'
    job_metadata_complete = '{ "jobStatus": "COMPLETED" }'
    job_metadata_failed = '{ "jobStatus": "FAILED" }'
    job_data_endpoint = '{ "id": "123456", "updated_at": "2017-01-01T00:00:00.000Z" }'
    job_data_endpoint2 = '{ "id": "234567", "updated_at": "2017-01-01T00:00:00.000Z" }'
    job_data_customer = '{ "id": "123456", "updated_at": "2017-01-01T00:00:00.000Z" }'
    es_data_endpoint = [{
            "_index": "bi-index-endpointvolume",
            "_type": "endpointvolume",
            "_id": "123456",
            "_version_type": "external",
            "_version": 1483228800000,
            "_ignore": 409,
            "_source": { u'id': u'123456', u'updated_at': u'2017-01-01T00:00:00.000Z' }}]
    es_data_endpoint2 = [{
            "_index": "bi-index-endpointvolume",
            "_type": "endpointvolume",
            "_id": "234567",
            "_version_type": "external",
            "_version": 1483228800000,
            "_ignore": 409,
            "_source": { u'id': u'234567', u'updated_at': u'2017-01-01T00:00:00.000Z' }}]
    es_data_customer = [{
            "_index": "bi-index-customer",
            "_type": "customer",
            "_id": "123456",
            "_version_type": "external",
            "_version": 1483228800000,
            "_ignore": 409,
            "_source": { u'id': u'123456', u'updated_at':
                u'2017-01-01T00:00:00.000Z', u'region': 'eu-central-1' }}]
    es_duplicate_return = (0, [{u'index': {u'status': 409}}]) 
    es_failed_return = (0, [{u'index': {u'status': 500}}]) 

    mock_s3 = moto.mock_s3()
    es = 'es'


    def setUp(self):
        self.mock_s3.start()


    def tearDown(self):
        self.mock_s3.stop()


    def init_s3(self, data):
        session = boto3.Session()
        self.s3 = session.resource(
                's3', 
                config=Config(signature_version='s3v4'))
        bucket = self.s3.create_bucket(
                Bucket=self.bucket_name, 
                CreateBucketConfiguration={
                    'LocationConstraint': 'eu-central-1'})

        for keyName in data:
            self.s3.Object(self.bucket_name, keyName).put(Body=data[keyName])

        self.bucket = self.s3.Bucket(self.bucket_name)


    def get_metadata_key(self, job_name):
        return 'meta/' + job_name + '/eu-central-1/' + self.job_run_id + '.json'


    def get_data_key(self, job_name, index=1):
        key = 'data/' + job_name + '/eu-central-1/' + self.job_run_id + '/'
        key += job_name[:-6].lower() + 'part-' + str(index)
        return key


    def get_es_bulk_data(self, job_name):
        job_name = job_name[:-6].lower()



    @mock.patch("sophos.bi_import_job.elasticsearch")
    def test_job_with_one_data_file_is_imported_successfully(self,
            mock_elasticsearch):
        job_name = 'EndpointVolumeETLJob'
        data = {
            self.get_metadata_key(job_name) : self.job_metadata_complete,
            self.get_data_key(job_name) : self.job_data_endpoint }

        self.init_s3(data)

        result = import_bi_job(self.bucket, self.es, self.region, job_name,
                self.job_run_id)
        assert(result == True)

        mock_elasticsearch.helpers.bulk.assert_called_with(
                self.es, 
                self.es_data_endpoint,
                raise_on_error=False,
                max_chunk_bytes=10000000)


    @mock.patch("sophos.bi_import_job.elasticsearch")
    def test_job_with_two_data_files_is_imported_successfully(self,
            mock_elasticsearch):
        job_name = 'EndpointVolumeETLJob'
        data = {
            self.get_metadata_key(job_name) : self.job_metadata_complete,
            self.get_data_key(job_name, 2) : self.job_data_endpoint2,
            self.get_data_key(job_name) : self.job_data_endpoint }

        self.init_s3(data)

        result = import_bi_job(self.bucket, self.es, self.region, job_name,
                self.job_run_id)
        assert(result == True)

        # Seems like assert_has_calls should work here but for some reason
        # it fails.
        assert(mock_elasticsearch.helpers.bulk.call_args_list ==
                [mock.call(self.es, self.es_data_endpoint,
                    raise_on_error=False, max_chunk_bytes=10000000),
                mock.call(self.es, self.es_data_endpoint2,
                    raise_on_error=False, max_chunk_bytes=10000000)])


    @mock.patch("sophos.bi_import_job.elasticsearch")
    def test_region_added_to_customer_job(self,
            mock_elasticsearch):
        job_name = 'CustomerETLJob'
        data = {
            self.get_metadata_key(job_name) : self.job_metadata_complete,
            self.get_data_key(job_name) : self.job_data_customer }

        self.init_s3(data)

        result = import_bi_job(self.bucket, self.es, self.region, job_name,
                self.job_run_id)
        assert(result == True)
        mock_elasticsearch.helpers.bulk.assert_called_with(
                self.es, 
                self.es_data_customer,
                raise_on_error=False,
                max_chunk_bytes=10000000)


    def test_job_is_skipped_if_run_was_not_successful(self):
        job_name = 'EndpointVolumeETLJob'
        data = {
            self.get_metadata_key(job_name) : self.job_metadata_failed,
            self.get_data_key(job_name) : self.job_data_endpoint }

        self.init_s3(data)

        result = import_bi_job(self.bucket, self.es, self.region, job_name,
                self.job_run_id)
        assert(result == False)


    @mock.patch("sophos.bi_import_job.elasticsearch")
    def test_duplicate_import_errors_are_ignored(self,
            mock_elasticsearch):
        job_name = 'EndpointVolumeETLJob'
        data = {
            self.get_metadata_key(job_name) : self.job_metadata_complete,
            self.get_data_key(job_name) : self.job_data_endpoint }

        self.init_s3(data)

        mock_elasticsearch.helpers.bulk.return_value = self.es_duplicate_return
        result = import_bi_job(self.bucket, self.es, self.region, job_name,
                self.job_run_id)
        assert(result == True)

        mock_elasticsearch.helpers.bulk.assert_called_with(
                self.es, 
                self.es_data_endpoint,
                raise_on_error=False,
                max_chunk_bytes=10000000)


    @mock.patch("sophos.bi_import_job.elasticsearch")
    def test_failed_import_errors_are_reported(self,
            mock_elasticsearch):
        job_name = 'EndpointVolumeETLJob'
        data = {
            self.get_metadata_key(job_name) : self.job_metadata_complete,
            self.get_data_key(job_name) : self.job_data_endpoint }

        self.init_s3(data)

        mock_elasticsearch.helpers.bulk.return_value = self.es_failed_return
        result = import_bi_job(self.bucket, self.es, self.region, job_name,
                self.job_run_id)
        assert(result == False)

        mock_elasticsearch.helpers.bulk.assert_called_with(
                self.es, 
                self.es_data_endpoint,
                raise_on_error=False,
                max_chunk_bytes=10000000)

