#!/usr/bin/env python
# vim: autoindent expandtab shiftwidth=4 filetype=python

# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Test sophos.mongo module.
"""

# Import test module FIRST to make sure there are no dependencies.
import sophos.mongo

import json
import mock
import unittest

class MongoTest(unittest.TestCase):
    """Test sophos.mongo module."""

    def test_get_mongo_connection_args_no_config_files(self):
        """Test case where none of the files being read exist."""

        with mock.patch("__builtin__.open") as open_mock:
            open_mock.side_effect = IOError()

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod"),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos"),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod", "mongos"),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod"),
                    [])

    @staticmethod
    def get_open_func(contents):
        """Return open function for patching."""

        def my_open(filename):
            content = contents.get(filename)
            if content is None:
                raise IOError(filename)

            file_object = mock.mock_open(read_data=content).return_value
            file_object.__iter__.return_value = content.splitlines(True)

            return file_object

        return my_open

    def test_get_mongo_connection_args_only_mongod_conf(self):
        """Test case where only /etc/mongod.conf is found."""

        my_open = self.get_open_func({
            "/etc/mongod.conf": "net:\n    port: 12345\n"
        })

        with mock.patch("__builtin__.open", new=my_open):
            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod"),
                    ["--port", "12345"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos"),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod", "mongos"),
                    ["--port", "12345"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod"),
                    ["--port", "12345"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod", argv=["foo", "--bar", "baz"]),
                    ["--port", "12345"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod", argv=["foo", "--port", "13711"]),
                    [])

    def test_get_mongo_connection_args_only_mongos_conf(self):
        """Test case where only /etc/mongos.conf is found."""

        my_open = self.get_open_func({
            "/etc/mongos.conf": "net:\n    port: 67890\n"
        })

        with mock.patch("__builtin__.open", new=my_open):
            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod"),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos"),
                    ["--port", "67890"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod", "mongos"),
                    ["--port", "67890"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod"),
                    ["--port", "67890"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod", argv=["foo", "--bar", "baz"]),
                    ["--port", "67890"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod", argv=["foo", "--port", "13722"]),
                    [])

    def test_get_mongo_connection_args_mongod_and_mongos_conf(self):
        """Test case where both /etc/mongod.conf and /etc/mongos.conf are found."""

        my_open = self.get_open_func({
            "/etc/mongod.conf": "net:\n    port: 12345\n",
            "/etc/mongos.conf": "net:\n    port: 67890\n"
        })

        with mock.patch("__builtin__.open", new=my_open):
            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod"),
                    ["--port", "12345"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos"),
                    ["--port", "67890"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod", "mongos"),
                    ["--port", "12345"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod"),
                    ["--port", "67890"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod", argv=["foo", "--bar", "baz"]),
                    ["--port", "67890"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod", argv=["foo", "--port", "13733"]),
                    [])

    def test_get_mongo_connection_args_replset_json_under_etc_mongos(self):
        """Test case where /etc/mongos/config/replica-set.json is found."""

        my_open = self.get_open_func({
            "/etc/mongos/config/replica-set.json": json.dumps({
                "admin_username":   "ADMIN$USERNAME",
                "admin_password":   "ADMIN$PASSWORD",
                "client_username":  "CLIENT$USERNAME",
                "client_password":  "CLIENT$PASSWORD",
                "region":           "eu-central-1",
                "replica_set":      "rs0000",
                "shared_secret":    "Ssshhh!",
                "vpc_name":         "CloudStation"
            })
        })

        # Since this path is associated with the mongos service we can only access
        # the username and password if we request access to that service.

        with mock.patch("__builtin__.open", new=my_open):
            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod"),
                    [])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos"),
                    ["--username", "ADMIN$USERNAME", "--password", "ADMIN$PASSWORD", "--authenticationDatabase", "admin"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongod", "mongos"),
                    ["--username", "ADMIN$USERNAME", "--password", "ADMIN$PASSWORD", "--authenticationDatabase", "admin"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod"),
                    ["--username", "ADMIN$USERNAME", "--password", "ADMIN$PASSWORD", "--authenticationDatabase", "admin"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args("mongos", "mongod", argv=["foo", "--bar", "baz"]),
                    ["--username", "ADMIN$USERNAME", "--password", "ADMIN$PASSWORD", "--authenticationDatabase", "admin"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(
                        "mongos",
                        "mongod",
                        argv=["foo", "--username", "baz"]),
                    ["--password", "ADMIN$PASSWORD", "--authenticationDatabase", "admin"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(
                        "mongos",
                        "mongod",
                        argv=["foo", "--password", "wuttlewhat"]),
                    ["--username", "ADMIN$USERNAME", "--authenticationDatabase", "admin"])

            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(
                        "mongos",
                        "mongod",
                        argv=["foo", "--username", "vgyjnbgh", "--password", "ghfdssdq"]),
                    ["--authenticationDatabase", "admin"])

    def test_get_mongo_connection_args_replset_json_under_mongodata(self):
        """Test case where /mongodata/config/replica-set.json is found."""

        my_open = self.get_open_func({
            "/mongodata/config/replica-set.json": json.dumps({
                "admin_username":   "ADMIN$USERNAME",
                "admin_password":   "ADMIN$PASSWORD",
                "client_username":  "CLIENT$USERNAME",
                "client_password":  "CLIENT$PASSWORD",
                "region":           "eu-central-1",
                "replica_set":      "rs0000",
                "shared_secret":    "Ssshhh!",
                "vpc_name":         "CloudStation"
            })
        })

        # Since this path is independent of service we don't have to specify
        # a service to access the username and password.

        with mock.patch("__builtin__.open", new=my_open):
            self.assertEqual(
                    sophos.mongo.get_mongo_connection_args(),
                    ["--username", "ADMIN$USERNAME", "--password", "ADMIN$PASSWORD", "--authenticationDatabase", "admin"])

if __name__ == "__main__":
    unittest.main()
