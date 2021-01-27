#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Test sophos.aws module.
"""

# Import test module FIRST to make sure there are no dependencies.
import sophos.aws

import boto3
import unittest


class AwsHelperSubclass(sophos.aws.AwsHelper):
    def doit(self):
        pass

    def doit_with_underscores(self):
        pass


class AwsHelperTest(unittest.TestCase):
    def test_ctor_with_no_args(self):
        aws = sophos.aws.AwsHelper()

    def test_ctor_with_region(self):
        aws = sophos.aws.AwsHelper(region="us-west-2")
        self.assertEqual(aws.region(), "us-west-2")

    def test_docstring_assignment(self):
        aws = sophos.aws.AwsHelper(region="us-west-2")
        method = aws.ec2_delete_volume
        ec2 = boto3.client("ec2", region_name="us-west-2")
        self.assertEqual(method.__doc__, ec2.delete_volume.__doc__)

    def test_instance_methods(self):
        # Make sure instance methods with and without _ are handled appropriately.
        aws = sophos.aws.AwsHelper(region="us-west-2")
        self.assertEqual(aws.availability_zone.__class__.__name__, "instancemethod")  # pylint: disable=no-member
        self.assertEqual(aws.region.__class__.__name__, "instancemethod")  # pylint: disable=no-member

    def test_generated_method(self):
        # Make sure generated methods are handled appropriately.
        aws = sophos.aws.AwsHelper(region="us-west-2")
        self.assertEqual(aws.ec2_delete_volume.__class__.__name__, "function")

    def test_undefined_methods(self):
        # Make sure undefined methods with and without _ are handled appropriately.
        aws = sophos.aws.AwsHelper(region="us-west-2")
        with self.assertRaises(Exception):
            aws.bogus
        with self.assertRaises(Exception):
            aws.bogus_with_underscores

    def test_instance_subclass_methods(self):
        # Make sure instance methods with and without _ are handled appropriately.
        aws = AwsHelperSubclass(region="us-west-2")
        self.assertEqual(aws.availability_zone.__class__.__name__, "instancemethod")
        self.assertEqual(aws.region.__class__.__name__, "instancemethod")
        self.assertEqual(aws.doit_with_underscores.__class__.__name__, "instancemethod")  # pylint: disable=no-member
        self.assertEqual(aws.doit.__class__.__name__, "instancemethod")  # pylint: disable=no-member

    def test_generated_subclass_method(self):
        # Make sure generated methods are handled appropriately.
        aws = AwsHelperSubclass(region="us-west-2")
        self.assertEqual(aws.ec2_delete_volume.__class__.__name__, "function")

    def test_undefined_subclass_methods(self):
        # Make sure undefined methods with and without _ are handled appropriately.
        aws = AwsHelperSubclass(region="us-west-2")
        with self.assertRaises(Exception):
            aws.bogus
        with self.assertRaises(Exception):
            aws.bogus_with_underscores


if __name__ == "__main__":
    unittest.main()
