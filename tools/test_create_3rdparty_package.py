#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the create_3rdparty_package utility.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import create_3rdparty_package

import os
import unittest

class ChefPackageFileCreatorTest(unittest.TestCase):
    """
    Unit tests for class ChefPackageFileCreator.
    """

    def test_get_download_items(self):
        c = create_3rdparty_package.ChefPackageFileCreator()
        c.set_version("3.4.5")

        items = c.get_download_items()
        self.assertIsInstance(items, list)
        self.assertEqual(len(items), 1)

        item = items[0]

        self.assertIsInstance(item.filename, basestring)
        self.assertGreater(len(item.filename), 0)

        self.assertIsInstance(item.url, basestring)
        self.assertGreater(len(item.url), 0)
        self.assertIn("omnitruck-direct.chef.io", item.url)

        self.assertIsInstance(item.wget_options, list)
        self.assertEqual(len(item.wget_options), 0)

    def test_get_package_file_basename(self):
        c = create_3rdparty_package.ChefPackageFileCreator()
        c.set_version("3.4.5")
        self.assertEqual(c.get_package_file_basename(), "chef-3.4.5")

    def test_get_package_name(self):
        c = create_3rdparty_package.ChefPackageFileCreator()
        self.assertEqual(c.get_package_name(), "chef")

    def test_get_sample_version(self):
        c = create_3rdparty_package.ChefPackageFileCreator()
        sample_version = c.get_sample_version()
        self.assertIsInstance(sample_version, basestring)
        self.assertGreater(len(sample_version), 0)
        self.assertEqual(sample_version.strip(), sample_version)


class GenericPackageFileCreatorTest(unittest.TestCase):
    """
    Unit tests for class GenericPackageFileCreatorTest
    """

    def cmp_version(self, test, expected):
        self.assertEqual(test.version, expected['version'] )
        self.assertEqual(test.major, expected['major'])
        self.assertEqual(test.minor, expected['minor'])
        self.assertEqual(test.micro, expected['micro'])
        self.assertEqual(test.patch, expected['patch'])
        self.assertEqual(test.build, expected['build'])
        self.assertEqual(test.nano,  expected['nano'])
        self.assertEqual(test.numeric_version, expected['numeric_version'] )

    def test_set_version(self):
        data = [
            {
                'test_name': '3 component version',
                'test': {
                    'name': 'test_package 1',
                    'version': '1.2.3',
                    'files': [{
                        'url': 'http://example.com/test_file-{version}.tar.gz'
                    }]
                },
                'expected' : {
                    'version': '1.2.3',
                    'major': 1,
                    'minor': 2,
                    'micro': 3,
                    'patch': 3,
                    'nano': None,
                    'build': None,
                    'numeric_version': 1002003000000
                }
            },
            {
                'test_name': '4 component hyphen version',
                'test': {
                    'name': 'test_package 1',
                    'version': '19.28.37-46',
                    'files': [{
                        'url': 'http://example.com/test_file-{version}.tar.gz'
                    }]
                },
                'expected' : {
                    'version': '19.28.37-46',
                    'major': 19,
                    'minor': 28,
                    'micro': 37,
                    'patch': 37,
                    'build': 46,
                    'nano': 46,
                    'numeric_version': 19028037004600
                }
            }
        ]

        for tests in data:
            test = tests['test']
            c = create_3rdparty_package.GenericPackageFileCreator(test)
            c.set_version(test['version'])
            self.cmp_version(c,tests['expected'])

    def test_get_download_items(self):
        data = [{
                'test_name': 'simple package',
                'test': {
                    'name': 'test_package',
                    'version': '1.2.3',
                    'files': [{
                        'url': 'http://example.com/test_file-{version}.tar.gz'
                    }]
                },
                'expected' : [
                    create_3rdparty_package.PackageFileCreator.DownloadItem('test_file-1.2.3.tar.gz','http://example.com/test_file-1.2.3.tar.gz', None, None, None)
                ]
        }]

        for tests in data:
            test = tests['test']
            c = create_3rdparty_package.GenericPackageFileCreator(test)
            result = c._get_download_items()
            self.assertEqual(result, tests['expected'], tests['test_name'])


class JDKPackageFileCreatorTest(unittest.TestCase):
    """
    Unit tests for class JDKPackageFileCreator.
    """

    def test_set_version(self):
        c = create_3rdparty_package.JDKPackageFileCreator()

        # Happy path.
        c.set_version("1.7.0_71-b14")
        self.assertEqual(c.version, "1.7.0_71-b14")
        self.assertEqual(c.major, 7)
        self.assertEqual(c.minor, 71)
        self.assertEqual(c.build, 14)

        # Sad paths.
        with self.assertRaises(Exception):
            c.set_version("3")
        with self.assertRaises(Exception):
            c.set_version("3.0")
        with self.assertRaises(Exception):
            c.set_version("3.0.8.1")

    def test_get_download_items(self):
        c = create_3rdparty_package.JDKPackageFileCreator()
        c.set_version("1.7.0_71-b14")

        items = c.get_download_items()
        self.assertIsInstance(items, list)
        self.assertEqual(len(items), 2)

        item = items[0]

        self.assertIsInstance(item.filename, basestring)
        self.assertGreater(len(item.filename), 0)

        self.assertIsInstance(item.url, basestring)
        self.assertGreater(len(item.url), 0)
        self.assertIn("download.oracle.com", item.url)

        self.assertIsInstance(item.wget_options, list)
        self.assertGreater(len(item.wget_options), 0)
        self.assertIn("--no-check-certificate", item.wget_options)
        self.assertIn("--no-cookies", item.wget_options)
        self.assertIn("Cookie: oraclelicense=accept-securebackup-cookie", item.wget_options)

    def test_get_package_file_basename(self):
        c = create_3rdparty_package.JDKPackageFileCreator()
        c.set_version("1.7.0_71-b14")
        self.assertEqual(c.get_package_file_basename(), "jdk-1.7.0_71-b14")

    def test_get_package_name(self):
        c = create_3rdparty_package.JDKPackageFileCreator()
        self.assertEqual(c.get_package_name(), "jdk")

    def test_get_sample_version(self):
        c = create_3rdparty_package.JDKPackageFileCreator()
        sample_version = c.get_sample_version()
        self.assertIsInstance(sample_version, basestring)
        self.assertGreater(len(sample_version), 0)
        self.assertEqual(sample_version.strip(), sample_version)


class MongodbMmsPackageFileCreatorTest(unittest.TestCase):
    """
    Unit tests for class MongodbMmsPackageFileCreator.
    """

    def test_set_version_valid(self):
        c = create_3rdparty_package.MongodbMmsPackageFileCreator()

        # Happy path.
        c.set_version("3.4.7.479-1")
        self.assertEqual(c.version, "3.4.7.479-1")
        self.assertEqual(c.major, 3)
        self.assertEqual(c.minor, 4)
        self.assertEqual(c.micro, 7)
        self.assertEqual(c.nano, 479)
        self.assertEqual(c.pico, 1)
        self.assertEqual(c.patch, 7)
        self.assertEqual(c.build, 479)
        self.assertEqual(c.release, 1)

    def test_set_version_valid(self):
        c = create_3rdparty_package.MongodbMmsPackageFileCreator()

        # Happy path.
        c.set_version("3.4.7.479-1")
        self.assertEqual(c.version, "3.4.7.479-1")
        self.assertEqual(c.major, 3)
        self.assertEqual(c.minor, 4)
        self.assertEqual(c.micro, 7)
        self.assertEqual(c.nano, 479)
        self.assertEqual(c.pico, 1)
        self.assertEqual(c.patch, 7)
        self.assertEqual(c.build, 479)
        self.assertEqual(c.release, 1)
        self.assertEqual(c.numeric_version, 3004007479001)

    def test_set_version_invalid_non_3_digit(self):
        c = create_3rdparty_package.MongodbMmsPackageFileCreator()

        with self.assertRaises(ValueError):
            c.set_version("3.4.7.1479-1")

    def test_set_version_invalid_missing_group(self):
        c = create_3rdparty_package.MongodbMmsPackageFileCreator()

        with self.assertRaises(ValueError):
            c.set_version("3.4.7-1")

    def test_get_download_items(self):
        c = create_3rdparty_package.MongodbMmsPackageFileCreator()
        c.set_version("1.2.3.4-5")

        self.assertEqual(
            [
                create_3rdparty_package.PackageFileCreator.DownloadItem(
                    'mongodb-mms-1.2.3.4-5.x86_64.rpm',
                    'https://downloads.mongodb.com/on-prem-mms/rpm/mongodb-mms-1.2.3.4-5.x86_64.rpm',
                    []
                )
            ],
            c.get_download_items()
        )


class MongodbPackageFileCreatorTest(unittest.TestCase):
    """
    Unit tests for class MongodbPackageFileCreator.
    """

    def test_set_version(self):
        c = create_3rdparty_package.MongodbPackageFileCreator()

        # Happy path.
        c.set_version("3.0.8")
        self.assertEqual(c.version, "3.0.8")
        self.assertEqual(c.major, 3)
        self.assertEqual(c.minor, 0)
        self.assertEqual(c.patch, 8)

        # Sad paths.
        with self.assertRaises(ValueError):
            c.set_version("3")
        with self.assertRaises(ValueError):
            c.set_version("3.0")

    def test_get_download_items(self):
        c = create_3rdparty_package.MongodbPackageFileCreator()
        c.set_version("3.2.4")

        items = c.get_download_items()
        self.assertIsInstance(items, list)
        self.assertEqual(len(items), len(c.RPM_NAMES))

        for item in items:
            self.assertIsInstance(item.filename, basestring)
            self.assertGreater(len(item.filename), 0)

            self.assertIsInstance(item.url, basestring)
            self.assertIn("https://repo.mongodb.org/yum/amazon/", item.url)
            self.assertIn(c.version, item.url)

            self.assertIsInstance(item.wget_options, list)
            self.assertEqual(len(item.wget_options), 0)

        for rpm_name in c.RPM_NAMES:
            rpm_found = False
            rpm_substring = "/x86_64/RPMS/%s-%s-1.amzn1.x86_64.rpm" % (rpm_name, c.version)
            for item in items:
                if rpm_substring in item.url:
                    rpm_found = True
                    break
            self.assertTrue(rpm_found, "rpm '%s' not found in download items" % rpm_name)

    def test_get_package_file_basename(self):
        c = create_3rdparty_package.MongodbPackageFileCreator()
        c.set_version("3.2.4")
        self.assertEqual(c.get_package_file_basename(), "mongodb-3.2.4")

    def test_get_package_name(self):
        c = create_3rdparty_package.MongodbPackageFileCreator()
        self.assertEqual(c.get_package_name(), "mongodb")

    def test_get_sample_version(self):
        c = create_3rdparty_package.MongodbPackageFileCreator()
        sample_version = c.get_sample_version()
        self.assertIsInstance(sample_version, basestring)
        self.assertGreater(len(sample_version), 0)
        self.assertEqual(sample_version.strip(), sample_version)


class SophosFluentdPackageFileCreatorTest(unittest.TestCase):
    """
    Unit tests for class SophosFluentdPackageFileCreator.
    """
    def __init__(self, *args, **kwargs):
        super(self.__class__, self).__init__(*args, **kwargs)
        self.script_path = os.path.dirname(os.path.realpath(__file__))

    def test_get_download_items(self):
        c = create_3rdparty_package.SophosFluentdPackageFileCreator(self.script_path)

        items = c.get_download_items()

        self.assertIsInstance(items, list)
        self.assertEqual(len(items), 0)

    def test_get_package_name(self):
        c = create_3rdparty_package.SophosFluentdPackageFileCreator(self.script_path)
        self.assertEqual(c.get_package_name(), "sophos-fluentd")

    def test_get_sample_version(self):
        c = create_3rdparty_package.SophosFluentdPackageFileCreator(self.script_path)
        sample_version = c.get_sample_version()
        self.assertIsInstance(sample_version, basestring)
        self.assertGreater(len(sample_version), 0)
        self.assertEqual(sample_version.strip(), sample_version)


class TomcatPackageFileCreatorTest(unittest.TestCase):
    """
    Unit tests for class TomcatPackageFileCreator.
    """

    def test_set_version(self):
        c = create_3rdparty_package.TomcatPackageFileCreator()

        # Happy path.
        c.set_version("8.0.32")
        self.assertEqual(c.version, "8.0.32")
        self.assertEqual(c.major, 8)
        self.assertEqual(c.minor, 0)
        self.assertEqual(c.patch, 32)

        # Sad paths.
        with self.assertRaises(Exception):
            c.set_version("8")
        with self.assertRaises(Exception):
            c.set_version("8.0")

    def test_get_download_items(self):
        c = create_3rdparty_package.TomcatPackageFileCreator()
        c.set_version("8.0.32")

        items = c.get_download_items()
        self.assertIsInstance(items, list)
        self.assertEqual(len(items), 2)

        tgz_item = None
        md5_item = None

        for item in items:
            self.assertIsInstance(item.filename, basestring)
            self.assertGreater(len(item.filename), 0)

            self.assertIsInstance(item.url, basestring)
            self.assertGreater(len(item.url), 0)

            self.assertIsInstance(item.wget_options, list)
            self.assertEqual(len(item.wget_options), 0)

            if item.url.endswith(".tar.gz"):
                tgz_item = item
            elif item.url.endswith(".tar.gz.md5"):
                md5_item = item
            else:
                self.fail("get_download_items() returned an unexpected url: %s" % item.url)

        self.assertIsNotNone(tgz_item, "get_download_items() didn't return a .tar.gz url")
        self.assertIsNotNone(md5_item, "get_download_items() didn't return a .tar.gz.md5 url")

        # No point checking that the URLs contain apache.org,
        # as we may reasonably add support for downloading tomcat
        # from one of the mirror sites.

    def test_get_package_file_basename(self):
        c = create_3rdparty_package.TomcatPackageFileCreator()
        c.set_version("8.0.32")
        self.assertEqual(c.get_package_file_basename(), "tomcat8.0.32")

    def test_get_package_name(self):
        c = create_3rdparty_package.TomcatPackageFileCreator()
        self.assertEqual(c.get_package_name(), "tomcat")

    def test_get_sample_version(self):
        c = create_3rdparty_package.TomcatPackageFileCreator()
        sample_version = c.get_sample_version()
        self.assertIsInstance(sample_version, basestring)
        self.assertGreater(len(sample_version), 0)
        self.assertEqual(sample_version.strip(), sample_version)


if __name__ == '__main__':
    unittest.main()
