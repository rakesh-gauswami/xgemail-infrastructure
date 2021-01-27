#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016-2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
AWS utilities for Sophos Central applications.
"""

import cStringIO
import itertools
import logging
import subprocess
import time

import boto3
import botocore.client

import sophos.common


class AwsException(Exception):
    pass

class AwsSession(object):
    """
    Use the session object to create a session used to manage resources of a specific region.
    """
    def __init__(self, profile=None, region=None):
        """
        Specify a profile name and a region to create, update, delete resources.

        :param profile: The name of the profile specified in the configuration file
        :param region: The name of the region to direct the calls to (us-west-2,us-east-1, eu-west-1,...)
        """
        self._profile = profile
        self._region = region

    def create(self):
        """
        Creates a boto3 session object that can be used to create AWS client objects.

        :returns session: The boto3 session object
        """
        session = None

        if self._profile is not None:
            session = boto3.session.Session(profile_name=self._profile, region_name=self._region)
        else:
            session = boto3.session.Session(region_name=self._region)

        return session

class AwsHelper(object):
    """
    Collection of helper methods and boto3 method wrappers for AWS.

    This class has two main purposes:

    First, consolidate boiler-plate code written by various people in various
    python files into a single class with a coherent style and interface.

    Second, provide an interface to AWS that is easy to unit test by making
    it easy to use alternate client objects that can mimic client responses
    without actually communicating with AWS.

    Client objects can be created explicitly or implicitly, as needed.
    Implicit creation is supported when the service endpoint region matches
    the default region specified in the class constructor or can be determined
    by extracting the region from the availability zone returned by the
    "ec2-metadata -z" command (which is only available on EC2 instances).
    Explicit creation is required in all other cases.

        import sophos.aws

        # Explicit creation:
        aws = sophos.aws.AwsHelper()
        aws.add_client("ec2", region="us-west-2")
        aws.ec2_delete_volume(VolumeId="vol-12345678")

        # Implicit creation, use region specified in constructor:
        aws = sophos.aws.AwsHelper(region="us-west-2")
        aws.ec2_delete_volume(VolumeId="vol-12345678")

        # Implicit creation, use region for EC2 instance code runs on:
        aws = sophos.aws.AwsHelper()
        aws.ec2_delete_volume(VolumeId="vol-12345678")

    Methods that operate on boto3 client objects are dynamically generated
    in the overridden __getattr__ method and then bound to the object.
    The service name and client method name are determined by parsing the
    name argument: the portion of the name before the first underscore is
    assumed to be the service name, the portion of the name after the first
    underscore is assumed to be the client method name.

    Generated methods get assigned the same docstring as the client methods
    they call, so you can look at the documentation for a method easily in
    the python interpreter:

        $ python
        Python 2.7.5 (default, Mar  9 2014, 22:15:05) 
        [GCC 4.2.1 Compatible Apple LLVM 5.0 (clang-500.0.68)] on darwin
        Type "help", "copyright", "credits" or "license" for more information.
        >>> import sophos.aws
        >>> aws = sophos.aws.AwsHelper(region="us-west-2")
        >>> help(aws.ec2_delete_volume)

    The resulting code is easy to write using the boto3 documentation as
    a reference, and is easy to read too:

    Here is a sample of code that might be run on an EC2 instance:

        aws = sophos.aws.AwsHelper()

        response = aws.ec2_create_volume(
                AvailabilityZone=aws.availabilty_zone(),
                SnapshotId=snapshot_id)

        volume_id = response["VolumeId"]

        response = aws.ec2_attach_volume(
                VolumeId=volume_id,
                InstanceId=aws.instance_id(),
                Device="/dev/xvdh")

        while True:
            response = aws.ec2_describe_volumes(VolumeIds=[volume_id])
            state = response["Volumes"][0]["State"]
            if state == "in-use":
                break
            assert state == "available"
    """

    def __init__(self, session=None, config=None, region=None, logger=None, retry_limit_minutes=5):
        """
        Initialize AwsHelper object.

        ``session`` is an instance of class boto3.session.Session, or at
        least an object with a client method like the one for that class.
        It is used to create new client objects.  If ``session`` is None,
        then the boto3.client method will be used instead.

        ``config`` is an instance of class botocore.client.Config that
        will be used to configure clients.  If ``config`` is None, then
        an instance of botocore.client.Config with signature_version set
        to "s3v4" will be used instead.

        ``region`` is the default AWS region for each new client's endpoint
        when the endpoint region is not specified.  If ``region`` is None,
        then when clients are create without specifying an endpoint region,
        the region in which the current EC2 instance is running will be used.

        ``logger`` is either the name of a logger or an instance of class
        logging.Logger.  It is used to log execution of client methods.

        ``retry_limit_minutes`` is the maximum amount of time we are willing
        to spend retrying a single client method that is being throttled by AWS.
        If ``retry_limit_minutes`` is None or 0, then throttled requests will
        not be retried.
        """

        # Optional session object used to create new clients.
        self._session = session

        # Config object used to configure clients.
        if config is None:
            config = botocore.client.Config(signature_version="s3v4")
        self._config = config

        # Dictionary mapping service names to clients.
        self._clients = {}

        # Availability zone for the current AWS EC2 instance.
        # May be None for AWS clients running outside of AWS.
        self._availability_zone = None

        # Region for the current AWS EC2 instance.
        # May be None for AWS clients running outside of AWS.
        self._region = region

        # Instance ID for the current AWS EC2 instance.
        # May be None for AWS clients running outside of AWS.
        self._instance_id = None

        # Instance type for the current AWS EC2 instance.
        # May be None for AWS clients running outside of AWS.
        self._instance_type = None

        # Private IP address.
        # May be None for AWS clients running outside of AWS.
        self._local_ipv4 = None

        # Logger object for recording AWS method execution.
        if logger is None:
            logger = logging.getLogger()
        elif isinstance(logger, basestring):
            logger = logging.getLogger(logger)
        self._logger = logger

        # Time limit for retries on throttled requests.
        if retry_limit_minutes is None:
            retry_limit_minutes = 0
        self._retry_limit_minutes = retry_limit_minutes


    @staticmethod
    def _ec2_metadata(option):
        output = subprocess.check_output(["/opt/aws/bin/ec2-metadata", option])
        value = output.split(":", 1)[-1].strip()
        return value


    def availability_zone(self):
        """
        Return the availability zone for the current AWS EC2 instance.
        """

        if self._availability_zone is None:
            self._availability_zone = self._ec2_metadata("-z")

        return self._availability_zone


    def region(self):
        """
        Return the region for the current AWS EC2 instance.
        """

        if self._region is None:
            self._region = self.availability_zone()[:-1]

        return self._region


    def instance_id(self):
        """
        Return the instance ID for the current AWS EC2 instance.
        """

        if self._instance_id is None:
            self._instance_id = self._ec2_metadata("-i")

        return self._instance_id


    def instance_type(self):
        """
        Return the instance type for the current AWS EC2 instance.
        """

        if self._instance_type is None:
            self._instance_type = self._ec2_metadata("-t")

        return self._instance_type


    def local_ipv4(self):
        """
        Return the local (private) IP address for the current AWS EC2 instance.
        """

        if self._local_ipv4 is None:
            self._local_ipv4 = self._ec2_metadata("-o")

        return self._local_ipv4


    def new_client(self, service, region=None):
        """
        Return a new client object for a particular AWS service.

        ``service`` is the name of the service, e.g. "ec2".

        ``region`` is the region containing the endpoint used to access
        the service.  If ``region`` is None, then the region in which the
        current host (assumed to be an AWS EC2 instance) is running.

        The returned client is not cached.
        """

        if region is None:
            region = self.region()

        if self._session is None:
            client = boto3.client(service, region_name=region, config=self._config)
        else:
            client = self._session.client(service, region_name=region, config=self._config)

        return client


    def add_client(self, service, region=None):
        """
        Add a new client object for a particular AWS service.

        ``service`` is the name of the service, e.g. "ec2".

        ``region`` is the region containing the endpoint used to access
        the service.  If ``region`` is None, then the region in which the
        current host (assumed to be an AWS EC2 instance) is running.

        If a client object has already been added for the specified
        service, then it will be replaced.
        """

        client = self.new_client(service, region=region)

        self._clients[service] = client

        return client


    def client(self, service, region=None):
        """
        Return the client object to use for the specified service.
        Create the client object if it doesn't already exist.

        ``service`` is the name of the service, e.g. "ec2".

        ``region`` is the region containing the endpoint used to access
        the service.  If ``region`` is None, then the region in which the
        current host (assumed to be an AWS EC2 instance) is running.
        """

        if service not in self._clients:
            self.add_client(service, region=region)

        return self._clients[service]


    def _call_with_retry(self, method, *args, **kwargs):
        deadline = time.time() + self._retry_limit_minutes * 60

        for attempt in itertools.count():
            try:
                return method(*args, **kwargs)
            except botocore.exceptions.ClientError as e:
                if e.response["Error"]["Code"] not in ("Throttling", "RequestLimitExceeded"):
                    raise
                delay_seconds = 2 ** attempt
                if time.time() + delay_seconds > deadline:
                    raise
                time.sleep(delay_seconds)

    def _check_response(self, service, method, response):
        response_metadata = response.get("ResponseMetadata", {})
        http_status_code = response_metadata.get("HTTPStatusCode")
        summary = "boto3 response status: %s for request: %s.%s" % (http_status_code, service, method)

        # Summary log level depends on status code.
        level = logging.INFO if http_status_code == 200 else logging.ERROR
        self._logger.log(level, "%s", summary)

        # Detail log level is always debug.
        if self._logger.isEnabledFor(logging.DEBUG):
            response_dump = sophos.common.pretty_json_dumps(response)
            for line in response_dump.splitlines():
                self._logger.debug("boto3 response details: %s", line.rstrip())

        # Raise exception on any failure.
        if http_status_code != 200:
            raise AwsException(summary)

        return response


    def __getattr__(self, name):
        """
        Override the default implementation to dynamically generate methods
        that operate on boto3 client objects.

        ``name`` is the potential method name, consisting of the service name,
        an underscore, and the client method name, e.g. "ec2_delete_volume".

        If a client for the given service has not already been added, it will
        be added using either the endpoint region specified in the constructor
        or the region extracted from the current EC2 instance's availability
        zone.


        This method is only called for attributes that do not exist for the
        target object.  This means that it will not be called for pre-defined
        methods, like "availability_zone".  We attach each generated method
        to the object using setattr, so this method will not be called multiple
        times for the same method name.
        """

        # Parse the attribute name into service and method names.
        service_name, method_name = name.split("_", 1)

        # Lookup the client and method before we generate the new method
        # so we fail as early as possible.
        client = self.client(service_name)
        method = getattr(client, method_name)

        def generated_method(*args, **kwargs):
            # Set client here to allow client to be changed.
            client = self.client(service_name)
            method = getattr(client, method_name)

            response = self._call_with_retry(method, *args, **kwargs)

            self._check_response(service_name, method_name, response)

            return response


        # Copy the docstring from the client method.
        generated_method.__doc__ = method.__doc__

        # Remember the generated method so we don't repeat this unnecessarily.
        setattr(self, name, generated_method)

        return generated_method


    def get_bucket_location(self, bucket):
        """
        Return name of AWS region where ``bucket`` is located.

        This convenience method wraps a call to the S3 get_bucket_location
        method with code that translates the LocationConstraint according
        to the description found here:

        http://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGETlocation.html
        """

        # TODO: Cache bucket locations.

        # Create temporary client without resetting region for an existing S3
        # service client.
        client = self.new_client("s3", region="us-west-2")

        response = client.get_bucket_location(Bucket=bucket)

        region = response["LocationConstraint"]

        if region is None:
            region = "us-east-1"
        elif region == "EU":
            region = "eu-west-1"

        return region


    def get_kms_key_id(self, alias_name):
        """
        Return KMS key id for the key with alias ``alias_name``, or None if
        there is no KMS key with that alias.

        ``alias_name`` should start with "alias/", e.g. "alias/account-stuff".
        """

        next_marker = None
        while True:
            kwargs = {} if next_marker is None else { "Marker": next_marker }
            response = self.kms_list_aliases(**kwargs)
            aliases = response["Aliases"]
            for alias in aliases:
                if alias["AliasName"] == alias_name:
                    return alias["TargetKeyId"]
            next_marker = response.get("NextMarker")
            if next_marker is None:
                break

        return None

    def upload_data_to_s3(self, data, s3_bucket, s3_key, kms_key=None, content_type=None):
        """
        Upload the bytes in ``data`` to the specified location in S3.
        Encrypt the data at rest using either the specified KMS key or S3 key.
        Specify content_type, e.g. "text/text" or "text/html", to allow the
        uploaded object to be opened in the browser from the AWS console.
        """

        bucket_region = self.get_bucket_location(s3_bucket)
        bucket_specific_aws = AwsHelper(region=bucket_region)
        s3_client = bucket_specific_aws.client("s3", region=bucket_region)

        kms_key_id = kms_key
        if kms_key_id is not None and kms_key_id.startswith("alias/"):
            kms_key_id = bucket_specific_aws.get_kms_key_id(kms_key_id)

        if kms_key_id is None:
            extra_args = {
                "ServerSideEncryption": "AES256"
            }
        else:
            extra_args = {
                "ServerSideEncryption": "aws:kms",
                "SSEKMSKeyId": kms_key_id
            }

        if content_type is not None:
            extra_args["ContentType"] = content_type

        return s3_client.upload_fileobj(
                cStringIO.StringIO(data),
                s3_bucket,
                s3_key,
                extra_args)
