#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Test sophos.amis module.
"""

# Import test module FIRST to make sure there are no dependencies.
import sophos.amis

import botocore.exceptions
import sophos.fake_object
import unittest

class AmiLookupTest(unittest.TestCase):
    ebs_images_differing_only_in_version = [
        {
            "Architecture": "x86_64",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/xvda",
                    "Ebs": {
                        "DeleteOnTermination": True,
                        "Encrypted": False,
                        "SnapshotId": "snap-e1275fa6",
                        "VolumeSize": 8,
                        "VolumeType": "standard"
                    }
                }
            ],
            "CreationDate": "2016-03-16T23:42:54.000Z",
            "Description": "Amazon Linux AMI 2016.03.0 x86_64 HVM EBS",
            "Hypervisor": "xen",
            "ImageId": "ami-c928c1a9",
            "ImageLocation": "amazon/amzn-ami-hvm-2016.03.0.x86_64-ebs",
            "ImageOwnerAlias": "amazon",
            "ImageType": "machine",
            "Name": "amzn-ami-hvm-2016.03.0.x86_64-ebs",
            "OwnerId": "137112412989",
            "Public": True,
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "State": "available",
            "VirtualizationType": "hvm"
        },
        {
            "Architecture": "x86_64",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/xvda",
                    "Ebs": {
                        "DeleteOnTermination": True,
                        "Encrypted": False,
                        "SnapshotId": "snap-449d9102",
                        "VolumeSize": 8,
                        "VolumeType": "standard"
                    }
                }
            ],
            "CreationDate": "2016-04-30T00:32:29.000Z",
            "Description": "Amazon Linux AMI 2016.03.1 x86_64 HVM EBS",
            "Hypervisor": "xen",
            "ImageId": "ami-d8f704b8",
            "ImageLocation": "amazon/amzn-ami-hvm-2016.03.1.x86_64-ebs",
            "ImageOwnerAlias": "amazon",
            "ImageType": "machine",
            "Name": "amzn-ami-hvm-2016.03.1.x86_64-ebs",
            "OwnerId": "137112412989",
            "Public": True,
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "State": "available",
            "VirtualizationType": "hvm"
        }
    ]

    s3_images_differing_only_in_version = [
        {
            "Architecture": "x86_64",
            "BlockDeviceMappings": [],
            "CreationDate": "2016-03-16T23:39:00.000Z",
            "Description": "Amazon Linux AMI 2016.03.0 x86_64 HVM S3",
            "Hypervisor": "xen",
            "ImageId": "ami-152bc275",
            "ImageLocation": "amzn-ami-us-west-2/amzn-ami-hvm-2016.03.0.x86_64.manifest.xml",
            "ImageOwnerAlias": "amazon",
            "ImageType": "machine",
            "Name": "amzn-ami-hvm-2016.03.0.x86_64-s3",
            "OwnerId": "137112412989",
            "Public": True,
            "RootDeviceType": "instance-store",
            "SriovNetSupport": "simple",
            "State": "available",
            "VirtualizationType": "hvm"
        },
        {
            "Architecture": "x86_64",
            "BlockDeviceMappings": [],
            "CreationDate": "2016-04-30T00:28:18.000Z",
            "Description": "Amazon Linux AMI 2016.03.1 x86_64 HVM S3",
            "Hypervisor": "xen",
            "ImageId": "ami-3cf4075c",
            "ImageLocation": "amzn-ami-us-west-2/amzn-ami-hvm-2016.03.1.x86_64.manifest.xml",
            "ImageOwnerAlias": "amazon",
            "ImageType": "machine",
            "Name": "amzn-ami-hvm-2016.03.1.x86_64-s3",
            "OwnerId": "137112412989",
            "Public": True,
            "RootDeviceType": "instance-store",
            "SriovNetSupport": "simple",
            "State": "available",
            "VirtualizationType": "hvm"
        }
    ]

    images_differing_in_more_than_version = [
        {
            "Architecture": "x86_64",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/xvda",
                    "Ebs": {
                        "DeleteOnTermination": True,
                        "Encrypted": False,
                        "SnapshotId": "snap-6a31cc3a",
                        "VolumeSize": 8,
                        "VolumeType": "gp2"
                    }
                }
            ],
            "CreationDate": "2016-04-13T08:11:33.000Z",
            "Description": "Instance with vPV Agent",
            "Hypervisor": "xen",
            "ImageId": "ami-5c38cf3c",
            "ImageLocation": "073159000218/amzn-ami-hvm-2016.03.0.x86_64-gp2-with-vpv-agent",
            "ImageType": "machine",
            "Name": "amzn-ami-hvm-2016.03.0.x86_64-gp2-with-vpv-agent",
            "OwnerId": "073159000218",
            "Public": True,
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "State": "available",
            "VirtualizationType": "hvm"
        },
        {
            "Architecture": "x86_64",
            "BlockDeviceMappings": [
                {
                    "DeviceName": "/dev/xvda",
                    "Ebs": {
                        "DeleteOnTermination": True,
                        "Encrypted": False,
                        "SnapshotId": "snap-eef4cdae",
                        "VolumeSize": 8,
                        "VolumeType": "gp2"
                    }
                }
            ],
            "CreationDate": "2016-03-16T23:43:04.000Z",
            "Description": "Amazon Linux AMI 2016.03.0 x86_64 HVM GP2",
            "Hypervisor": "xen",
            "ImageId": "ami-c229c0a2",
            "ImageLocation": "amazon/amzn-ami-hvm-2016.03.0.x86_64-gp2",
            "ImageOwnerAlias": "amazon",
            "ImageType": "machine",
            "Name": "amzn-ami-hvm-2016.03.0.x86_64-gp2",
            "OwnerId": "137112412989",
            "Public": True,
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "SriovNetSupport": "simple",
            "State": "available",
            "VirtualizationType": "hvm"
        }
    ]

    def test_get_describe_images_filters(self):
        self.assertEqual(
                sophos.amis.get_describe_images_filters({}),
                [])

        self.assertEqual(
                sophos.amis.get_describe_images_filters({
                    "name": "foo",
                }),
                [{
                    "Name": "name",
                    "Values": ["foo"]
                }])

        self.assertEqual(
                sophos.amis.get_describe_images_filters({
                    "name": ["foo"],
                }),
                [{
                    "Name": "name",
                    "Values": ["foo"]
                }])

        self.assertEqual(
                sophos.amis.get_describe_images_filters({
                    "name": ["foo", "bar"],
                }),
                [{
                    "Name": "name",
                    "Values": ["foo", "bar"]
                }])

        self.assertEqual(
                sophos.amis.get_describe_images_filters({
                    "is-public": True,
                    "name": ["foo", "bar"],
                    "architecture": "x86_64",
                    "hypervisor": "xen"
                }),
                [{
                    "Name": "architecture",
                    "Values": ["x86_64"]
                }, {
                    "Name": "hypervisor",
                    "Values": ["xen"]
                }, {
                    "Name": "is-public",
                    "Values": [True]
                }, {
                    "Name": "name",
                    "Values": ["foo", "bar"]
                }])

    def test_get_image_signature(self):
        self.assertEqual(
            sophos.amis.get_image_signature(self.ebs_images_differing_only_in_version[0]),
            sophos.amis.get_image_signature(self.ebs_images_differing_only_in_version[1]))

        self.assertEqual(
            sophos.amis.get_image_signature(self.s3_images_differing_only_in_version[0]),
            sophos.amis.get_image_signature(self.s3_images_differing_only_in_version[1]))

        self.assertNotEqual(
            sophos.amis.get_image_signature(self.images_differing_in_more_than_version[0]),
            sophos.amis.get_image_signature(self.images_differing_in_more_than_version[1]))

    @staticmethod
    def queue_result(ec2, query, images):
        # Generate Filters list from resource query.
        filters = sophos.amis.get_describe_images_filters(query)

        # Tell the ec2 fake object what images we expect to see for that query.
        ec2.queue_result(
            {
                "Images": images,
                "ResponseMetadata": {
                    "HTTPStatusCode": 200,
                    "RequestId": "1ff1c1cd-d089-4443-9885-ec87caa4e07a"
                }
            },
            "describe_images",
            Filters=filters)

    @staticmethod
    def queue_exception(ec2, query, exception):
        # Generate Filters list from resource query.
        filters = sophos.amis.get_describe_images_filters(query)

        # Tell the ec2 fake object what exception to raise for that query.
        ec2.queue_result(
            sophos.fake_object.FakeExceptionHolder(exception),
            "describe_images",
            Filters=filters)

    def test_no_matches(self):
        with sophos.fake_object.fake_object() as ec2:
            queries = [{ "name": "*jethro*" }]

            self.queue_result(ec2, queries[0], [])

            image_data, error_message = sophos.amis.find_image_data(queries, ec2)

            self.assertIsNone(image_data)

            self.assertIsNotNone(error_message)
            self.assertEqual(error_message, "no matches")

    def test_multiple_non_equivalent_matches(self):
        with sophos.fake_object.fake_object() as ec2:
            queries = [{}]

            self.queue_result(
                    ec2,
                    queries[0],
                    self.images_differing_in_more_than_version)

            image_data, error_message = sophos.amis.find_image_data(queries, ec2)

            self.assertIsNone(image_data)

            self.assertIsNotNone(error_message)
            self.assertTrue(error_message.startswith("ambiguous match for query 0: found 2 variations"))

    def test_multiple_equivalent_matches(self):
        with sophos.fake_object.fake_object() as ec2:
            queries = [{}]

            self.queue_result(
                    ec2,
                    queries[0],
                    self.ebs_images_differing_only_in_version)

            image_data, error_message = sophos.amis.find_image_data(queries, ec2)

            self.assertIsNotNone(image_data)
            for image in self.ebs_images_differing_only_in_version:
                self.assertGreaterEqual(image_data["CreationDate"], image["CreationDate"])

            self.assertIsNone(error_message)

    def test_amazon_linux(self):
        with sophos.fake_object.fake_object() as ec2:
            queries = [{
                "name": "amzn-ami-hvm-2016.03*",

                # owner-alias is set for Amazon images but not custom ones.
                # Best to set it when we do want Amazon images to avoid
                # accidental mismatches with images derived from Amazon
                # images that reuse the parent AMI name.
                "owner-alias": "amazon",

                # Specify root volume type -- Amazon Linux has variants
                # with gp2 and standard.
                "block-device-mapping.volume-type": "gp2",
            }]

            self.queue_result(
                    ec2,
                    queries[0],
                    [
                        # Actual output for this query:
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-eef4cdae",
                                        "VolumeSize": 8,
                                        "VolumeType": "gp2"
                                    }
                                }
                            ],
                            "CreationDate": "2016-03-16T23:43:04.000Z",
                            "Description": "Amazon Linux AMI 2016.03.0 x86_64 HVM GP2",
                            "Hypervisor": "xen",
                            "ImageId": "ami-c229c0a2",
                            "ImageLocation": "amazon/amzn-ami-hvm-2016.03.0.x86_64-gp2",
                            "ImageOwnerAlias": "amazon",
                            "ImageType": "machine",
                            "Name": "amzn-ami-hvm-2016.03.0.x86_64-gp2",
                            "OwnerId": "137112412989",
                            "Public": True,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-61034a9c",
                                        "VolumeSize": 8,
                                        "VolumeType": "gp2"
                                    }
                                }
                            ],
                            "CreationDate": "2016-04-30T00:32:29.000Z",
                            "Description": "Amazon Linux AMI 2016.03.1 x86_64 HVM GP2",
                            "Hypervisor": "xen",
                            "ImageId": "ami-d0f506b0",
                            "ImageLocation": "amazon/amzn-ami-hvm-2016.03.1.x86_64-gp2",
                            "ImageOwnerAlias": "amazon",
                            "ImageType": "machine",
                            "Name": "amzn-ami-hvm-2016.03.1.x86_64-gp2",
                            "OwnerId": "137112412989",
                            "Public": True,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        }
                    ])

            image_data, error_message = sophos.amis.find_image_data(queries, ec2)

            self.assertIsNotNone(image_data)
            self.assertEqual(
                    image_data["Name"],
                    "amzn-ami-hvm-2016.03.1.x86_64-gp2")

            self.assertIsNone(error_message)

    def test_sophos_updated_amazon_linux(self):
        with sophos.fake_object.fake_object() as ec2:
            queries = [{
                # First query for a specific feature branch.
                "name": "Sophos-Cloud-updated-amazon-linux-AMI@feature/CPLAT-12345@*"
            }, {
                # Second query falls back to the develop branch.
                "name": "Sophos-Cloud-updated-amazon-linux-AMI@develop@*"
            }]

            self.queue_result(
                    ec2,
                    queries[0],
                    [])

            self.queue_result(
                    ec2,
                    queries[1],
                    [
                        # Actual output for this query:
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-48c9a40e",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-01-27T16:08:41.000Z",
                            "Description": "Sophos Cloud updated-amazon-linux AMI develop-b3",
                            "Hypervisor": "xen",
                            "ImageId": "ami-379e7957",
                            "ImageLocation": "283871543274/Sophos-Cloud-updated-amazon-linux-AMI@develop@3",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-updated-amazon-linux-AMI@develop@3",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-926be0c7",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-01-26T20:19:34.000Z",
                            "Description": "Sophos Cloud updated-amazon-linux AMI develop-b2",
                            "Hypervisor": "xen",
                            "ImageId": "ami-5ea2453e",
                            "ImageLocation": "283871543274/Sophos-Cloud-updated-amazon-linux-AMI@develop@2",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-updated-amazon-linux-AMI@develop@2",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-3862ac6d",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-04-21T14:26:33.000Z",
                            "Description": "Sophos Cloud updated-amazon-linux AMI develop-b6",
                            "Hypervisor": "xen",
                            "ImageId": "ami-92f908f2",
                            "ImageLocation": "283871543274/Sophos-Cloud-updated-amazon-linux-AMI@develop@6",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-updated-amazon-linux-AMI@develop@6",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-5eed7618",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-03-25T14:00:33.000Z",
                            "Description": "Sophos Cloud updated-amazon-linux AMI develop-b5",
                            "Hypervisor": "xen",
                            "ImageId": "ami-c229c2a2",
                            "ImageLocation": "283871543274/Sophos-Cloud-updated-amazon-linux-AMI@develop@5",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-updated-amazon-linux-AMI@develop@5",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-169f1244",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-02-10T06:57:42.000Z",
                            "Description": "Sophos Cloud updated-amazon-linux AMI develop-b4",
                            "Hypervisor": "xen",
                            "ImageId": "ami-c34eafa3",
                            "ImageLocation": "283871543274/Sophos-Cloud-updated-amazon-linux-AMI@develop@4",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-updated-amazon-linux-AMI@develop@4",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        }
                    ])


            image_data, error_message = sophos.amis.find_image_data(queries, ec2)

            self.assertIsNotNone(image_data)
            self.assertEqual(
                    image_data["Name"],
                    "Sophos-Cloud-updated-amazon-linux-AMI@develop@6")

            self.assertIsNone(error_message)

    def test_sophos_java(self):
        with sophos.fake_object.fake_object() as ec2:
            queries = [{
                # NOTE: This example might not be the pattern we want to use.
                # Consider the release versions, e.g.:
                #   hmr-core-release/2016.22-java-11-1464289016
                # Notice that it does NOT specify any specific service.
                # No matter, this example is good enough for testing.
                "name": "hmr-core-develop-java-wifi-*"
            }]

            self.queue_result(
                    ec2,
                    queries[0],
                    [
                        # Actual output for this query:
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-2020b872",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdf",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-2155d162",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdg",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-ab6cd2f7",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdh",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-19e79d4c",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2015-08-04T21:33:31.000Z",
                            "Description": "Sophos, Inc. Prepared image of svc_develop-wifi_7.",
                            "Hypervisor": "xen",
                            "ImageId": "ami-356b6305",
                            "ImageLocation": "843638552935/hmr-core-develop-java-wifi-7",
                            "ImageType": "machine",
                            "Name": "hmr-core-develop-java-wifi-7",
                            "OwnerId": "843638552935",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-5ee6ff1b",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdf",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-8afd98d7",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdg",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-9c2cacd8",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdh",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-08b3274b",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2015-08-06T20:08:35.000Z",
                            "Description": "Sophos, Inc. Prepared image of svc_develop-wifi_10.",
                            "Hypervisor": "xen",
                            "ImageId": "ami-859890b5",
                            "ImageLocation": "843638552935/hmr-core-develop-java-wifi-10",
                            "ImageType": "machine",
                            "Name": "hmr-core-develop-java-wifi-10",
                            "OwnerId": "843638552935",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-75ebab27",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdf",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-2e8f5e70",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdg",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-10a73f4c",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdh",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-40299011",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2015-08-06T20:59:44.000Z",
                            "Description": "Sophos, Inc. Prepared image of svc_develop-wifi_11.",
                            "Hypervisor": "xen",
                            "ImageId": "ami-9d9b93ad",
                            "ImageLocation": "843638552935/hmr-core-develop-java-wifi-11",
                            "ImageType": "machine",
                            "Name": "hmr-core-develop-java-wifi-11",
                            "OwnerId": "843638552935",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-da024286",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdf",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-0a201359",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdg",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-80da6ac2",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                },
                                {
                                    "DeviceName": "/dev/xvdh",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-0cd03b59",
                                        "VolumeSize": 10,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2015-08-06T02:06:06.000Z",
                            "Description": "Sophos, Inc. Prepared image of svc_develop-wifi_9.",
                            "Hypervisor": "xen",
                            "ImageId": "ami-f1dcd4c1",
                            "ImageLocation": "843638552935/hmr-core-develop-java-wifi-9",
                            "ImageType": "machine",
                            "Name": "hmr-core-develop-java-wifi-9",
                            "OwnerId": "843638552935",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "VirtualizationType": "hvm"
                        }
                    ])

            image_data, error_message = sophos.amis.find_image_data(queries, ec2)

            self.assertIsNotNone(image_data)
            self.assertEqual(
                    image_data["Name"],
                    "hmr-core-develop-java-wifi-11")

            self.assertIsNone(error_message)

    def test_images_with_differently_sorted_tags(self):
        with sophos.fake_object.fake_object() as ec2:
            queries = [{
                "state": "available",
                "tag:Branch": "develop",
                "tag:Name": "sophos-central-base-amazon-linux",
            }]

            self.queue_result(
                    ec2,
                    queries[0],
                    [
                        # Actual output for this query:
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-59f97cbd",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-05-23T04:18:37.000Z",
                            "Description": "Sophos Cloud base-amazon-linux AMI develop-b34",
                            "Hypervisor": "xen",
                            "ImageId": "ami-19798d74",
                            "ImageLocation": "283871543274/Sophos-Cloud-base-amazon-linux-AMI@develop@34",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-base-amazon-linux-AMI@develop@b34",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "Tags": [
                                {
                                    "Key": "Branch",
                                    "Value": "develop"
                                },
                                {
                                    "Key": "Name",
                                    "Value": "sophos-central-base-amazon-linux"
                                },
                                {
                                    "Key": "Build",
                                    "Value": "34"
                                }
                            ],
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-cf6f962b",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-05-16T04:23:58.000Z",
                            "Description": "Sophos Cloud base-amazon-linux AMI develop-b33",
                            "Hypervisor": "xen",
                            "ImageId": "ami-4d5fb620",
                            "ImageLocation": "283871543274/Sophos-Cloud-base-amazon-linux-AMI@develop@33",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-base-amazon-linux-AMI@develop@33",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "Tags": [
                                {
                                    "Key": "Name",
                                    "Value": "sophos-central-base-amazon-linux"
                                },
                                {
                                    "Key": "Build",
                                    "Value": "33"
                                },
                                {
                                    "Key": "Branch",
                                    "Value": "develop"
                                }
                            ],
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-b8d5025b",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-05-09T04:17:20.000Z",
                            "Description": "Sophos Cloud base-amazon-linux AMI develop-b32",
                            "Hypervisor": "xen",
                            "ImageId": "ami-9d9f72f0",
                            "ImageLocation": "283871543274/Sophos-Cloud-base-amazon-linux-AMI@develop@32",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-base-amazon-linux-AMI@develop@32",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "Tags": [
                                {
                                    "Key": "Branch",
                                    "Value": "develop"
                                },
                                {
                                    "Key": "Name",
                                    "Value": "sophos-central-base-amazon-linux"
                                },
                                {
                                    "Key": "Build",
                                    "Value": "32"
                                }
                            ],
                            "VirtualizationType": "hvm"
                        },
                        {
                            "Architecture": "x86_64",
                            "BlockDeviceMappings": [
                                {
                                    "DeviceName": "/dev/xvda",
                                    "Ebs": {
                                        "DeleteOnTermination": True,
                                        "Encrypted": False,
                                        "SnapshotId": "snap-c8d8e5dc",
                                        "VolumeSize": 8,
                                        "VolumeType": "standard"
                                    }
                                }
                            ],
                            "CreationDate": "2016-05-30T04:19:37.000Z",
                            "Description": "Sophos Cloud base-amazon-linux AMI develop-b35",
                            "Hypervisor": "xen",
                            "ImageId": "ami-ce4ab9a3",
                            "ImageLocation": "283871543274/Sophos-Cloud-base-amazon-linux-AMI@develop@35",
                            "ImageType": "machine",
                            "Name": "Sophos-Cloud-base-amazon-linux-AMI@develop@35",
                            "OwnerId": "283871543274",
                            "Public": False,
                            "RootDeviceName": "/dev/xvda",
                            "RootDeviceType": "ebs",
                            "SriovNetSupport": "simple",
                            "State": "available",
                            "Tags": [
                                {
                                    "Key": "Name",
                                    "Value": "sophos-central-base-amazon-linux"
                                },
                                {
                                    "Key": "Build",
                                    "Value": "35"
                                },
                                {
                                    "Key": "Branch",
                                    "Value": "develop"
                                }
                            ],
                            "VirtualizationType": "hvm"
                        }
                    ])

            image_data, error_message = sophos.amis.find_image_data(queries, ec2)

            self.assertIsNone(error_message)

            self.assertIsNotNone(image_data)

            self.assertEqual(
                    image_data["Name"],
                    "Sophos-Cloud-base-amazon-linux-AMI@develop@35")

            self.assertIsNone(error_message)

    def test_describe_images_exception(self):
        with sophos.fake_object.fake_object() as ec2:
            queries = [{
                # Example of a bad qeuery -- "namex" is not a valid filter name.
                "namex": "hmr-core-develop-java-wifi-*"
            }]

            error_response = {
                "Error": {
                    "Code": "InvalidParameterValue",
                    "Message": "The filter 'namex' is invalid"
                }
            }

            client_error = botocore.exceptions.ClientError(error_response, "DescribeImages")

            self.queue_exception(ec2, queries[0], client_error)

            image_data, error_message = sophos.amis.find_image_data(queries, ec2)

            self.assertIsNone(image_data)

            self.assertEqual(
                    error_message,
                    # Yay, python automatically joins adjacent strings.
                    "ClientError: An error occurred (InvalidParameterValue) "
                    "when calling the DescribeImages operation: The filter "
                    "'namex' is invalid")

if __name__ == "__main__":
    unittest.main()
