#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import argparse
import boto3
import datetime
import dateutil
import elasticsearch
import elasticsearch.helpers
import json
import logging
import pytz
import sys
from botocore.client import Config

"""
Utility class to import a single BI job from S3 to ELK.  Can be run from
command line by itself, or invoked from bi_import.py in the hopper.  Also
used by bi_import_trigger lambda function.
"""

logger = logging.getLogger(__name__)

def import_bi_job(bucket, es, region, job_name, job_run_id, log_level=None):
    if log_level is not None:
        logger.setLevel(log_level)

    logger.info('Importing BI job %s:%s:%s', region, job_name, job_run_id)

    if not was_run_successful(bucket, region, job_name, job_run_id):
        logger.warning(
                'Job %s run %s was unsuccessful or could not be read, skipping import',
                job_name,
                job_run_id)
        return False
    
    # The list coming from S3 is lexicographically sorted, but the order in
    # which the files were written is naturally sorted.  While this probably
    # doesn't matter, sort the list in natural order just so the import is
    # happening in the same order as the export did.  This quick natural sort
    # relies on the fact that the names are always going to be of the form
    # collection-part-number, so we just sort by the numeric value of number.
    prefix = 'data/' + job_name + '/' + region + '/' + job_run_id + '/'
    job_files = get_job_files(bucket, prefix) 
    try:
        job_files = sorted(job_files, key=lambda f: int(f.split('-')[-1]))
    except:
        logger.exception('Error sorting job files for import')
        throw

    logger.info('Found %d files to import', len(job_files))
    errors_found = False
    for job_file in job_files:
        logger.info('  Processing job file %s', job_file)

        job_data = get_job_file_data(bucket, job_file)
        if len(job_data) == 0:
            logger.warning(
                    'Nothing found to import for BI job %s:%s:%s', 
                    region,
                    job_name,
                    job_run_id)
            return False

        process_job_data(job_name, region, job_data)
        result = import_job_data(es, job_name, job_data)
        errors_found = errors_found or not result

    if errors_found:
        logger.warning(
                'Import complete with errors for BI job %s:%s:%s', 
                region,
                job_name,
                job_run_id)

        return False

    logger.info(
            'Import complete for BI job %s:%s:%s',
            region,
            job_name,
            job_run_id)

    return True


def was_run_successful(bucket, region, job_name, job_run_id):
    run_metadata = get_run_metadata(bucket, region, job_name, job_run_id)
    return run_metadata[u'jobStatus'] == u'COMPLETED'


def get_run_metadata(bucket, region, job_name, job_run_id):
    key = 'meta/' + job_name + '/' + region + '/' + job_run_id + '.json'
    try:
        obj = bucket.Object(key)
        return json.loads(obj.get()['Body'].read())
    except:
        logging.exception('Failure to get run metadata from key %s', key)
        return json.loads('{ "jobStatus": "ERROR_READING" }')


def get_job_files(bucket, prefix):
    job_files = []

    for o in bucket.objects.filter(Prefix=prefix):
        job_files.append(o.key)

    return job_files


def get_job_file_data(bucket, job_file):
    obj = bucket.Object(job_file)
    raw_data = obj.get()['Body'].read()

    # Safety check - we shouldn't have any of the old XML data
    # lying around but at least in dev we do.  If the first 
    # character is a '<' we're likely looking at XML data and
    # should just return an empty list for processing.
    if raw_data[0] == '<':
        logger.warning('Found old XML data, ignoring')
        return []

    records = [json.loads(x) for x in raw_data.splitlines()]
    logger.info('    Found %d records', len(records))
    return records


def process_job_data(job_name, region, job_data):
    if job_name != 'CustomerETLJob':
        return

    logger.info('Adding region %s to job files', region)
    for i in range(0, len(job_data)):
        job_data[i][u'region'] = region


def import_job_data(es, job_name, job_data):
    # Job names are the collection name followed by ETLJob.  Strip off
    # the ETLJob portion for the record type and index name.
    record_type = job_name[:-6].lower()
    index = 'bi-index-' + record_type

    # Use the actual id from the collection as the id of the record in
    # elastic search.  This will ensure that updates overwrite instead of
    # creating new objects.  Version is calculated from the updated_at field
    # so re-running an older import will not clobber newer data.
    actions = [
            {
                "_index": index,
                "_type": record_type,
                "_id": record[u'id'],
                "_version_type": "external",
                "_version": get_version(record),
                "_ignore": 409,
                "_source": record
            }
            for record in job_data]
    
    logger.info('Doing bulk import on %d records for to index %s',
            len(actions), index)
    result = elasticsearch.helpers.bulk(
            es, 
            actions, 
            raise_on_error=False,
            max_chunk_bytes=10000000)
    errors = [r for r in result[1] if r[u'index'][u'status'] != 409]
    if len(errors) != 0:
        logger.error("Error importing data to ElasticSearch.")
        for e in errors:
            logger.error(e)

        return False

    return True


def get_version(record):
    update = dateutil.parser.parse(record[u'updated_at'])
    epoch = datetime.datetime.utcfromtimestamp(0).replace(tzinfo=pytz.UTC)
    timestamp = int((update - epoch).total_seconds() * 1000.0)

    return timestamp


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
            "--environment", 
            required=True,
            help="Environment to run import against")
    parser.add_argument(
            "--job",
            required=True,
            help="Job to import")
    parser.add_argument(
            "--region",
            required=True,
            help="Region to import")
    parser.add_argument(
            "--job-run-id",
            required=True,
            help="Job run ID to import")
    parser.add_argument(
            "--log-level",
            default='info',
            help="Logging level to run at")
    parser.add_argument(
            "--es-host",
            help="Override ES host to connect to")

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    logging.basicConfig(stream=sys.stderr)
    logger.setLevel(getattr(logging, args.log_level.upper(), None))
    logger.info(
            'Executing BI import for job %s:%s:%s',
            args.region,
            args.job,
            args.job_run_id)

    bucket_name = 'cloud-' + args.environment + '-biexport-eu-central-1'
    session = boto3.Session(region_name='eu-central-1')
    s3 = session.resource('s3', config=Config(signature_version='s3v4'))
    bucket = s3.Bucket(bucket_name)

    # Configure the ES host.
    es_host = 'bi-elk.cloudstation.eu-central-1.' + args.environment + '.hydra.sophos.com:80'
    if args.es_host is not None:
        es_host = args.es_host
    logger.info('Targeting ES host %s', es_host)

    es = elasticsearch.Elasticsearch(es_host, timeout=30)
    import_bi_job(bucket, es, args.region, args.job, args.job_run_id)
