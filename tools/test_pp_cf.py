#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# Import test module FIRST to make sure there are no dependencies.
import pp_cf

import json
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest


class CloudFormationPrettyPrinterTest(unittest.TestCase):
    # JSON tokenization tests.

    def get_json_tokens(self, text):
        return [token for token in pp_cf.iter_json_tokens(text)]

    def check_iter_json_tokens(self, text, expected_tokens):
        self.assertEqual(self.get_json_tokens(text), expected_tokens)

    def test_iter_json_tokens_empty_string(self):
        self.check_iter_json_tokens("", [])

    def test_iter_json_tokens_newline(self):
        self.check_iter_json_tokens("\n", [])

    def test_iter_json_tokens_whitespace(self):
        self.check_iter_json_tokens(" \t\n \t\n", [])

    def test_iter_json_tokens_numbers(self):
        self.check_iter_json_tokens("0", [("N", "0")])
        self.check_iter_json_tokens("1.2", [("N", "1.2")])
        self.check_iter_json_tokens("-1.2", [("N", "-1.2")])

    def test_iter_json_tokens_strings(self):
        self.check_iter_json_tokens('""', [("S", '""')])
        self.check_iter_json_tokens('" hi there! "', [("S", '" hi there! "')])
        self.check_iter_json_tokens(r'"\"quoted\""', [("S", r'"\"quoted\""')])

    def test_iter_json_tokens_keywords(self):
        self.check_iter_json_tokens("null", [("K", "null")])
        self.check_iter_json_tokens("true", [("K", "true")])
        self.check_iter_json_tokens("false", [("K", "false")])

    def test_iter_json_tokens_punctuation(self):
        self.check_iter_json_tokens(",", [("P", ",")])
        self.check_iter_json_tokens(":", [("P", ":")])
        self.check_iter_json_tokens("[]", [("P", "["), ("P", "]")])
        self.check_iter_json_tokens("{}", [("P", "{"), ("P", "}")])

    def test_iter_json_tokens_invalid(self):
        with self.assertRaises(pp_cf.JsonError):
            self.get_json_tokens("bogus")
        with self.assertRaises(pp_cf.JsonError):
            self.get_json_tokens("''")
        with self.assertRaises(pp_cf.JsonError):
            self.get_json_tokens("@")

    # Breadcrumb match tests.

    def test_match_breadcrumbs_empty_pattern(self):
        self.assertEqual(pp_cf.match_breadcrumbs([], []), True)
        self.assertEqual(pp_cf.match_breadcrumbs([], [], exact=True), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], []), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], [], exact=True), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["x", "y"], []), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["x", "y"], [], exact=True), False)

    def test_match_breadcrumbs_overlong_pattern(self):
        self.assertEqual(pp_cf.match_breadcrumbs([], [None]), False)
        self.assertEqual(pp_cf.match_breadcrumbs([], [None], exact=True), False)
        self.assertEqual(pp_cf.match_breadcrumbs([], ["x"]), False)
        self.assertEqual(pp_cf.match_breadcrumbs([], ["x"], exact=True), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], [None, "x"]), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], [None, "x"], exact=True), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], ["x", "x"]), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], ["x", "x"], exact=True), False)

    def test_match_breadcrumbs_single_pattern(self):
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], ["x"]), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["w", "x"], ["x"]), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], [None]), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["w", "x"], [None]), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], ["y"]), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["w", "x"], ["y"]), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], ["x"], exact=True), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["w", "x"], ["x"], exact=True), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], [None], exact=True), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["w", "x"], [None], exact=True), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["x"], ["y"], exact=True), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["w", "x"], ["y"], exact=True), False)

    def test_match_breadcrumbs_common_cases(self):
        # Top-level
        pattern = []
        self.assertEqual(pp_cf.match_breadcrumbs([], pattern, exact=True), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["anything"], pattern, exact=True), False)

        # The Metadata entry
        pattern = ["Metadata"]
        self.assertEqual(pp_cf.match_breadcrumbs(["Metadata"], pattern), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["Some", "prefixes", "then", "Metadata"], pattern), True)

        # Any Parameters child entry
        pattern = ["Parameters", None]
        self.assertEqual(pp_cf.match_breadcrumbs(["Parameters"], pattern), False)
        self.assertEqual(pp_cf.match_breadcrumbs(["Parameters", "Child"], pattern), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["Parameters", "Child", "Grandchild"], pattern), False)

        # The AWS::CloudFormation::Init entry
        pattern = [None, "Metadata", "AWS::CloudFormation::Init"]
        self.assertEqual(pp_cf.match_breadcrumbs(["Resources", "Name", "Metadata", "AWS::CloudFormation::Init"], pattern), True)
        self.assertEqual(pp_cf.match_breadcrumbs(["Metadata", "AWS::CloudFormation::Init"], pattern), False)

    # Constructor tests, indent option.

    def test_ctor_indent_default(self):
        pp = pp_cf.CloudFormationPrettyPrinter()
        self.assertEqual(pp.indent, pp_cf.DEFAULT_INDENT)
        self.assertEqual(len(pp.indent_segment), pp.indent)

    def test_ctor_indent_explicit(self):
        desired_indent = pp_cf.DEFAULT_INDENT * 3 + 1
        pp = pp_cf.CloudFormationPrettyPrinter(indent=desired_indent)
        self.assertEqual(pp.indent, desired_indent)
        self.assertEqual(len(pp.indent_segment), pp.indent)

    def test_ctor_indent_explicit_bool(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(indent=True)

    def test_ctor_indent_explicit_dict(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(indent={})

    def test_ctor_indent_explicit_list(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(indent=[])

    def test_ctor_indent_explicit_none(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(indent=None)

    def test_ctor_indent_explicit_string(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(indent="hello")

    def test_ctor_indent_explicit_stringized_int(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(indent="7")

    # Constructor tests, width option.

    def test_ctor_width_default(self):
        pp = pp_cf.CloudFormationPrettyPrinter()
        self.assertEqual(pp.width, pp_cf.DEFAULT_WIDTH)

    def test_ctor_width_explicit(self):
        desired_width = pp_cf.DEFAULT_WIDTH * 3 + 1
        pp = pp_cf.CloudFormationPrettyPrinter(width=desired_width)
        self.assertEqual(pp.width, desired_width)

    def test_ctor_width_explicit_bool(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(width=True)

    def test_ctor_width_explicit_dict(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(width={})

    def test_ctor_width_explicit_list(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(width=[])

    def test_ctor_width_explicit_none(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(width=None)

    def test_ctor_width_explicit_string(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(width="hello")

    def test_ctor_width_explicit_stringized_int(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(width="7")

    # Constructor tests, order option.

    def test_ctor_order_default(self):
        pp = pp_cf.CloudFormationPrettyPrinter()
        self.assertEqual(pp.order, pp_cf.DEFAULT_ORDER)

    def test_ctor_order_explicit_bool(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(order=True)

    def test_ctor_order_explicit_dict(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(order={})

    def test_ctor_order_explicit_list(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(order=[])

    def test_ctor_order_explicit_none(self):
        with self.assertRaises(StandardError):
            pp = pp_cf.CloudFormationPrettyPrinter(order=None)

    def test_ctor_order_explicit_string_valid_alpha(self):
        desired_order = pp_cf.ORDER_ALPHA
        pp = pp_cf.CloudFormationPrettyPrinter(order=desired_order)
        self.assertEqual(pp.order, desired_order)

    def test_ctor_order_explicit_string_valid_source(self):
        desired_order = pp_cf.ORDER_SOURCE
        pp = pp_cf.CloudFormationPrettyPrinter(order=desired_order)
        self.assertEqual(pp.order, desired_order)

    def test_ctor_order_explicit_string_invalid(self):
        with self.assertRaises(StandardError):
            pp_cf.CloudFormationPrettyPrinter(order="bogus")

    # Formatting tests.

    TEST_WIDTH = 80

    def pformat(self, text, **kwargs):
        if "width" not in kwargs:
            kwargs["width"] = self.TEST_WIDTH
        return pp_cf.pformat(text, **kwargs)

    def test_format_empty(self):
        self.assertEqual(self.pformat("{}"), "{}")

    def check_format(self, given, want, **kwargs):
        actual = self.pformat(given, **kwargs)
        wanted = textwrap.dedent(want).strip("\n")

        self.assertIsNotNone(actual)

        tmpdir = tempfile.mkdtemp()
        try:
            actual_path = os.path.join(tmpdir, "actual.json")
            with open(actual_path, "w") as fp:
                fp.write(actual)

            wanted_path = os.path.join(tmpdir, "wanted.json")
            with open(wanted_path, "w") as fp:
                fp.write(wanted)

            diff_argv = ["diff", "-U", "4", wanted_path, actual_path]
            diff_pipe = subprocess.Popen(diff_argv, stdout=subprocess.PIPE)
            diff_data = diff_pipe.communicate()
            diff_stdout = diff_data[0]

            if len(diff_stdout) > 0:
                sys.stderr.write(diff_stdout)

            self.assertEqual(len(diff_stdout), 0)
        finally:
            subprocess.check_call(["rm", "-rf", tmpdir])

    def test_format_template_version(self):
        self.check_format(
            """
            {
                "AWSTemplateFormatVersion":
                    "2010-09-09"
            }
            """,
            """
            { "AWSTemplateFormatVersion": "2010-09-09" }
            """,
            squeeze=True)

    def test_format_template_description(self):
        self.check_format(
            """
            {
                "Description": "Some random text here.",
                "AWSTemplateFormatVersion": "2010-09-09"
            }
            """,
            """
            {
                "AWSTemplateFormatVersion": "2010-09-09",

                "Description": "Some random text here."
            }
            """,
            squeeze=True)

    def test_format_template_metadata(self):
        self.check_format(
            """
            {
                "Description": "Some random text here.",
                "Metadata": { "Copyright": "2016", "Comments": [] },
                "AWSTemplateFormatVersion": "2010-09-09",
                "Resources": {
                    "MyResource": {
                        "Properties": {},
                        "Type": "My::Type",
                        "Metadata": {
                            "AAA": 0,
                            "Comment": "This is a comment",
                            "BBB": 1,
                            "Comments": "These are comments",
                            "Copyright": []
                        }
                    }
                }
            }
            """,
            """
            {
                "AWSTemplateFormatVersion": "2010-09-09",

                "Description": "Some random text here.",

                "Metadata": {
                    "Copyright": "2016",

                    "Comments": []
                },

                "Resources": {
                    "MyResource": {
                        "Type": "My::Type",
                        "Metadata": {
                            "Copyright": [],
                            "Comments": "These are comments",
                            "Comment": "This is a comment",
                            "AAA": 0,
                            "BBB": 1
                        },
                        "Properties": {}
                    }
                }
            }
            """,
            squeeze=True)

    def test_format_template_metadata_alternate_indent(self):
        self.check_format(
            """
            {
                "Description": "Some random text here.",
                "Metadata": { "Copyright": "2016", "Comments": [] },
                "AWSTemplateFormatVersion": "2010-09-09"
            }
            """,
            """
            {
              "AWSTemplateFormatVersion": "2010-09-09",

              "Description": "Some random text here.",

              "Metadata": {
                "Copyright": "2016",

                "Comments": []
              }
            }
            """,
            indent=2,
            squeeze=True)

    def test_format_template_resources(self):
        self.check_format(
            """
            {
                "Outputs": {
                    "BucketDomainName": {
                        "Description": "DNS name of the bucket",
                        "Value": {
                            "Fn::GetAtt" : [
                                "Bucket",
                                "DomainName"
                            ]
                        }
                    }
                },
                "Resources": {
                    "Bucket": {
                        "Condition": "CreateBucket",
                        "DeletionPolicy": "Retain",
                        "Metadata": {
                            "Comments": [
                            ],

                            "TODO": [
                            ]
                        },
                        "Properties": {
                            "VersioningConfiguration": {
                                "Status": "Enabled"
                            },
                            "BucketName": {
                                "Fn::Join": [
                                    "\\n", [
                                        "ami-bakery",
                                        { "Ref": "AWS::Region" }
                                    ]
                                ]
                            }
                        },
                        "Type": "AWS::S3::Bucket"
                    }
                },
                "Description": "Some random text here.",
                "Metadata": { "Copyright": "2016", "Comments": [] },
                "AWSTemplateFormatVersion": "2010-09-09"
            }
            """,
            """
            {
                "AWSTemplateFormatVersion": "2010-09-09",

                "Description": "Some random text here.",

                "Metadata": {
                    "Copyright": "2016",

                    "Comments": []
                },

                "Resources": {
                    "Bucket": {
                        "Type": "AWS::S3::Bucket",
                        "Condition": "CreateBucket",
                        "DeletionPolicy": "Retain",
                        "Metadata": {
                            "Comments": [],
                            "TODO": []
                        },
                        "Properties": {
                            "BucketName": {
                                "Fn::Join": [ "\\n", [
                                    "ami-bakery",
                                    { "Ref": "AWS::Region" }
                                ]]
                            },
                            "VersioningConfiguration": { "Status": "Enabled" }
                        }
                    }
                },

                "Outputs": {
                    "BucketDomainName": {
                        "Description": "DNS name of the bucket",
                        "Value": { "Fn::GetAtt": [ "Bucket", "DomainName" ] }
                    }
                }
            }
            """,
            squeeze=True)

    def test_format_template_cloudformation_init_config(self):
        self.check_format(
            """
            {
                "Resources": {
                    "MyInstance": {
                        "Type": "AWS::EC2::Instance",
                        "Metadata": {
                            "AWS::CloudFormation::Init": {
                                "config": {
                                    "commands": {},
                                    "files": {},
                                    "groups": {},
                                    "packages": {},
                                    "services": {},
                                    "sources": {},
                                    "users": {}
                                }
                            }
                        },
                        "Properties": {
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "MyInstance": {
                        "Type": "AWS::EC2::Instance",
                        "Metadata": {
                            "AWS::CloudFormation::Init": {
                                "config": {
                                    "packages": {},

                                    "groups": {},

                                    "users": {},

                                    "sources": {},

                                    "files": {},

                                    "commands": {},

                                    "services": {}
                                }
                            }
                        },
                        "Properties": {}
                    }
                }
            }
            """,
            squeeze=True)

    def test_format_template_cloudformation_init_configSets(self):
        self.check_format(
            """
            {
                "Resources": {
                    "MyInstance": {
                        "Type": "AWS::EC2::Instance",
                        "Metadata": {
                            "AWS::CloudFormation::Init": {
                                "install_b": {
                                },
                                "install_a": {
                                    "files": {
                                        "/var/install.sh": {
                                            "group": "root",
                                            "mode": "000444",
                                            "owner": "root",
                                            "source": "https://www.opscode.com/chef/install.sh"
                                        }
                                    },
                                    "commands": {
                                        "01_doit": {
                                            "command": "/bin/doit",
                                            "cwd": "/tmp"
                                        }
                                    }
                                },
                                "configSets": {
                                    "install": [
                                        "common",
                                        "install_a",
                                        "install_b"
                                    ],

                                    "update": [
                                        "common",
                                        "update_a",
                                        "update_b"
                                    ]
                                }
                            }
                        },
                        "Properties": {
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "MyInstance": {
                        "Type": "AWS::EC2::Instance",
                        "Metadata": {
                            "AWS::CloudFormation::Init": {
                                "configSets": {
                                    "install": [
                                        "common",
                                        "install_a",
                                        "install_b"
                                    ],
                                    "update":  [
                                        "common",
                                        "update_a",
                                        "update_b"
                                    ]
                                },

                                "install_a": {
                                    "files": {
                                        "/var/install.sh": {
                                            "source": "https://www.opscode.com/chef/install.sh",
                                            "owner":  "root",
                                            "group":  "root",
                                            "mode":   "000444"
                                        }
                                    },

                                    "commands": {
                                        "01_doit": {
                                            "command": "/bin/doit",
                                            "cwd": "/tmp"
                                        }
                                    }
                                },

                                "install_b": {}
                            }
                        },
                        "Properties": {}
                    }
                }
            }
            """,
            squeeze=True)

    def test_format_simple_lists_compactly(self):
        self.check_format(
            """
            {
                "Parameters": {
                    "InstanceType": {
                        "Description": "Amazon EC2 instance type",
                        "Type" : "String",
                        "Default" : "r3.large",
                        "AllowedValues": [
                            "m4.large", "m4.xlarge", "m4.2xlarge", "m4.4xlarge", "m4.10xlarge",
                            "r3.large", "r3.xlarge", "r3.2xlarge", "r3.4xlarge", "r3.8xlarge"
                        ]
                    },
                    "MongoSSLEnabled": {
                        "Description": "Specify yes to enable SSL",
                        "Type": "String",
                        "AllowedValues": [ "yes", "no" ],
                        "Default": "no"
                    }
                }
            }
            """,
            """
            {
                "Parameters": {
                    "InstanceType": {
                        "Description": "Amazon EC2 instance type",
                        "Type": "String",
                        "Default": "r3.large",
                        "AllowedValues": [
                            "m4.large",
                            "m4.xlarge",
                            "m4.2xlarge",
                            "m4.4xlarge",
                            "m4.10xlarge",
                            "r3.large",
                            "r3.xlarge",
                            "r3.2xlarge",
                            "r3.4xlarge",
                            "r3.8xlarge"
                        ]
                    },

                    "MongoSSLEnabled": {
                        "Description": "Specify yes to enable SSL",
                        "Type": "String",
                        "Default": "no",
                        "AllowedValues": [
                            "yes",
                            "no"
                        ]
                    }
                }
            }
            """,
            squeeze=True)

    def test_format_single_simple_dict_list_compactly(self):
        self.check_format(
            """
            {
                "Resources": {
                    "BastionInstance": {
                        "Properties": {
                            "AvailabilityZone": { "Fn::GetAtt": [ "PublicSubnet", "AvailabilityZone" ] },
                            "ImageId": { "Fn::FindInMap": [ "RegionMap", { "Ref": "AWS::Region" }, "ImageId" ] },
                            "NetworkInterfaces": [{
                                "GroupSet": [
                                    { "Ref": "BastionSecurityGroup" }
                                ],
                                "SubnetId": { "Ref": "PublicSubnet" }
                            }]
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "BastionInstance": {
                        "Properties": {
                            "AvailabilityZone": {
                                "Fn::GetAtt": [
                                    "PublicSubnet",
                                    "AvailabilityZone"
                                ]
                            },
                            "ImageId": {
                                "Fn::FindInMap": [
                                    "RegionMap",
                                    { "Ref": "AWS::Region" },
                                    "ImageId"
                                ]
                            },
                            "NetworkInterfaces": [{
                                "GroupSet": [{ "Ref": "BastionSecurityGroup" }],
                                "SubnetId": { "Ref": "PublicSubnet" }
                            }]
                        }
                    }
                }
            }
            """,
            squeeze=True)

    def test_format_dictionary_lists_compactly(self):
        self.check_format(
            """
            {
                "Resources": {
                    "MongoAutoScalingGroup": {
                        "Type": "AWS::AutoScaling::AutoScalingGroup",
                        "Properties": {
                            "AvailabilityZones": [
                                { "Fn::Select" : [
                                    { "Ref": "AvailabilityZoneIndex" },
                                    { "Fn::GetAZs" : { "Ref" : "AWS::Region" } }
                                ] }
                            ],
                            "Tags": [{
                                "Key": "Name",
                                "Value": {
                                    "Fn::Join":  [ ":", [
                                        { "Ref": "VpcName" },
                                        {
                                            "Fn::Join": [ "-", [
                                                "mongodb",
                                                { "Ref": "MongoReplicaSetName" },
                                                { "Fn::If": [
                                                    "IsConfigServer",
                                                    "configsvr",
                                                    { "Fn::Join": [
                                                        "",
                                                        [ "rs", { "Ref": "MongoShardingSetId" } ]
                                                    ]}
                                                ] },
                                                { "Ref": "MongoReplicaSetInstance" }
                                            ]]
                                        },
                                        { "Ref": "Branch" },
                                        { "Ref": "BundleVersion" }
                                    ]]
                                },
                                "PropagateAtLaunch": true
                            }, {
                                "Key": "BuildResultKey",
                                "Value": { "Ref": "BuildVersion" },
                                "PropagateAtLaunch": true
                            }, {
                                "Key": "BundleVersion",
                                "Value": { "Ref": "BundleVersion" },
                                "PropagateAtLaunch": true
                            }]
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "MongoAutoScalingGroup": {
                        "Type": "AWS::AutoScaling::AutoScalingGroup",
                        "Properties": {
                            "AvailabilityZones": [{
                                "Fn::Select": [
                                    { "Ref": "AvailabilityZoneIndex" },
                                    { "Fn::GetAZs": { "Ref": "AWS::Region" } }
                                ]
                            }],
                            "Tags": [{
                                "Key": "Name",
                                "Value": {
                                    "Fn::Join": [ ":", [
                                        { "Ref": "VpcName" },
                                        {
                                            "Fn::Join": [ "-", [
                                                "mongodb",
                                                { "Ref": "MongoReplicaSetName" },
                                                {
                                                    "Fn::If": [
                                                        "IsConfigServer",
                                                        "configsvr",
                                                        {
                                                            "Fn::Join": [ "", [
                                                                "rs",
                                                                {
                                                                    "Ref": "MongoShardingSetId"
                                                                }
                                                            ]]
                                                        }
                                                    ]
                                                },
                                                { "Ref": "MongoReplicaSetInstance" }
                                            ]]
                                        },
                                        { "Ref": "Branch" },
                                        { "Ref": "BundleVersion" }
                                    ]]
                                },
                                "PropagateAtLaunch": true
                            }, {
                                "Key": "BuildResultKey",
                                "Value": { "Ref": "BuildVersion" },
                                "PropagateAtLaunch": true
                            }, {
                                "Key": "BundleVersion",
                                "Value": { "Ref": "BundleVersion" },
                                "PropagateAtLaunch": true
                            }]
                        }
                    }
                }
            }
            """,
            squeeze=True)

    def test_format_fn_and_or_compactly(self):
        self.check_format(
            """
            {
                "Conditions": {
                    "IsConfigServer": { "Fn::Equals": [ { "Ref": "MongoConfigServer" }, "true" ] },

                    "IsInfDevelopmentEnvironment": {
                        "Fn::Or": [{ "Fn::Equals": [ { "Ref": "Environment" }, "inf" ] }, {
                            "Fn::Equals": [
                                { "Ref": "Environment" },
                                "qainf"
                            ]
                        }, { "Fn::Equals": [ { "Ref": "Environment" }, "dev" ] }]
                    },

                    "IsPrimaryShard": { "Fn::Equals": [ { "Ref": "MongoShardingSetId" }, "0" ] }
                }
            }
            """,
            """
            {
              "Conditions": {
                "IsConfigServer": { "Fn::Equals": [ { "Ref": "MongoConfigServer" }, "true" ] },

                "IsInfDevelopmentEnvironment": {
                  "Fn::Or": [
                    { "Fn::Equals": [ { "Ref": "Environment" }, "inf" ] },
                    { "Fn::Equals": [ { "Ref": "Environment" }, "qainf" ] },
                    { "Fn::Equals": [ { "Ref": "Environment" }, "dev" ] }
                  ]
                },

                "IsPrimaryShard": { "Fn::Equals": [ { "Ref": "MongoShardingSetId" }, "0" ] }
              }
            }
            """,
            indent=2,
            width=pp_cf.DEFAULT_WIDTH,
            squeeze=True)

    def test_format_fn_equals_compactly(self):
        self.check_format(
            """
            {
                "Conditions": {
                    "AliasesSpecified": {
                        "Fn::Not": [{
                            "Fn::Equals": [
                                {
                                    "Fn::Join": [
                                        "",
                                        { "Ref": "Aliases" }
                                    ]
                                },
                                ""
                            ]
                        }]
                    },

                    "AllowWriteMethods": {
                        "Fn::Equals": [
                            { "Ref": "AllowWriteMethods" },
                            "true"
                        ]
                    },

                    "DistributingLoggingSpecified": {
                        "Fn::Not": [{
                            "Fn::Equals": [
                                { "Ref": "LoggingBucket" },
                                ""
                            ]
                        }]
                    },

                    "OriginPathSpecified": {
                        "Fn::Not": [{
                            "Fn::Equals": [
                                { "Ref": "OriginPath" },
                                ""
                            ]
                        }]
                    },

                    "TrustedSignersSpecified": {
                        "Fn::Not": [{
                            "Fn::Equals": [
                                {
                                    "Fn::Join": [
                                        "",
                                        { "Ref": "TrustedSigners" }
                                    ]
                                },
                                ""
                            ]
                        }]
                    }
                }
            }
            """,
            """
            {
                "Conditions": {
                    "AliasesSpecified": {
                        "Fn::Not": [{
                            "Fn::Equals": [
                                { "Fn::Join": [ "", { "Ref": "Aliases" } ] },
                                ""
                            ]
                        }]
                    },

                    "AllowWriteMethods": {
                        "Fn::Equals": [
                            { "Ref": "AllowWriteMethods" },
                            "true"
                        ]
                    },

                    "DistributingLoggingSpecified": {
                        "Fn::Not": [{ "Fn::Equals": [ { "Ref": "LoggingBucket" }, "" ] }]
                    },

                    "OriginPathSpecified": {
                        "Fn::Not": [{ "Fn::Equals": [ { "Ref": "OriginPath" }, "" ] }]
                    },

                    "TrustedSignersSpecified": {
                        "Fn::Not": [{
                            "Fn::Equals": [
                                { "Fn::Join": [ "", { "Ref": "TrustedSigners" } ] },
                                ""
                            ]
                        }]
                    }
                }
            }
            """,
            squeeze=True)

    def test_format_fn_if_compactly(self):
        self.check_format(
            """
            {
                "Resources": {
                    "CloudFrontDistribution": {
                        "Properties": {
                            "DistributionConfig": {
                                "Aliases": {
                                    "Fn::If": [
                                        "AliasesSpecified",
                                        { "Ref": "Aliases" },
                                        { "Ref": "AWS::NoValue" }
                                    ]
                                },
                                "DefaultCacheBehavior": {
                                    "AllowedMethods": {
                                        "Fn::If": [
                                            "AllowWriteMethods",
                                            [ "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT" ],
                                            [ "GET", "HEAD" ]
                                        ]
                                    },
                                    "TrustedSigners": {
                                        "Fn::If": [
                                            "TrustedSignersSpecified",
                                            { "Ref": "TrustedSigners" },
                                            { "Ref": "AWS::NoValue" }
                                        ]
                                    }
                                }
                            }
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "CloudFrontDistribution": {
                        "Properties": {
                            "DistributionConfig": {
                                "Aliases": { "Fn::If": [ "AliasesSpecified", { "Ref": "Aliases" }, { "Ref": "AWS::NoValue" } ] },
                                "DefaultCacheBehavior": {
                                    "AllowedMethods": {
                                        "Fn::If": [
                                            "AllowWriteMethods",
                                            [
                                                "DELETE",
                                                "GET",
                                                "HEAD",
                                                "OPTIONS",
                                                "PATCH",
                                                "POST",
                                                "PUT"
                                            ],
                                            [
                                                "GET",
                                                "HEAD"
                                            ]
                                        ]
                                    },
                                    "TrustedSigners": {
                                        "Fn::If": [
                                            "TrustedSignersSpecified",
                                            { "Ref": "TrustedSigners" },
                                            { "Ref": "AWS::NoValue" }
                                        ]
                                    }
                                }
                            }
                        }
                    }
                }
            }
            """,
            width=pp_cf.DEFAULT_WIDTH,
            squeeze=True)

    def test_format_fn_join_compactly(self):
        self.check_format(
            """
            {
                "Resources": {
                    "CloudFrontDistribution": {
                        "Properties": {
                            "DistributionConfig": {
                                "PriceClass": {
                                    "Fn::Join": [ "", [
                                        "PriceClass_",
                                        { "Ref": "PriceClass" }
                                    ]]
                                }
                            }
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "CloudFrontDistribution": {
                        "Properties": {
                            "DistributionConfig": {
                                "PriceClass": {
                                    "Fn::Join": [ "", [
                                        "PriceClass_",
                                        { "Ref": "PriceClass" }
                                    ]]
                                }
                            }
                        }
                    }
                }
            }
            """,
            width=pp_cf.DEFAULT_WIDTH,
            squeeze=True)

    def test_format_fn_find_in_map_compactly(self):
        self.check_format(
            """
            {
                "Resources": {
                    "AMITemplateInstance": {
                        "Metadata": {
                            "AWS::CloudFormation::Init": {
                                "create_image": {
                                    "files": {
                                        "/var/sophos/modify_network_config": {
                                            "context": {
                                                "domain_name": {
                                                    "Fn::FindInMap": [
                                                        "RegionConfigMap",
                                                        { "Ref": "AWS::Region" },
                                                        "PrivateDns"
                                                    ]
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            """,
            """
            {
              "Resources": {
                "AMITemplateInstance": {
                  "Metadata": {
                    "AWS::CloudFormation::Init": {
                      "create_image": {
                        "files": {
                          "/var/sophos/modify_network_config": {
                            "context": {
                              "domain_name": { "Fn::FindInMap": [ "RegionConfigMap", { "Ref": "AWS::Region" }, "PrivateDns" ] }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            """,
            indent=2,
            width=pp_cf.DEFAULT_WIDTH,
            squeeze=True)

    def test_format_fn_select_compactly(self):
        self.check_format(
            """
            {
                "Resources": {
                    "Foo": {
                        "Properties": {
                            "P1": { "Fn::Select" : [ "0", { "Ref": "AvailabilityZones" }] },
                            "P2": { "Fn::Select" : [ "0", { "Fn::FindInMap" : [ "RegionMap", { "Ref": "AWS::Region" }, "PrivateSubnetCidrBlocks" ] } ] }
                        }
                    }
                }
            }
            """,
            """
            {
              "Resources": {
                "Foo": {
                  "Properties": {
                    "P1": { "Fn::Select": [ "0", { "Ref": "AvailabilityZones" } ] },
                    "P2": {
                      "Fn::Select": [
                        "0",
                        { "Fn::FindInMap": [ "RegionMap", { "Ref": "AWS::Region" }, "PrivateSubnetCidrBlocks" ] }
                      ]
                    }
                  }
                }
              }
            }
            """,
            indent=2,
            width=pp_cf.DEFAULT_WIDTH,
            squeeze=True)

    def test_align_dict_values(self):
        self.check_format(
            """
            {
                "Resources": {
                    "AMITemplateInstance": {
                        "Metadata": {
                            "AWS::CloudFormation::Init": {
                                "create_image": {
                                    "files": {
                                        "/var/sophos/cookbooks/attributes.json": {
                                            "content": {},
                                            "context": {
                                                "ami_bucket": { "Ref": "AMIBucket" },
                                                "ami_destination_regions": { "Ref": "AMIDestinationRegions" },
                                                "ami_launch_permissions": { "Ref": "AMILaunchPermissions" },
                                                "availability_zone": {
                                                    "Fn::Select": [
                                                        { "Ref": "AvailabilityZoneIndex" },
                                                        { "Fn::GetAZs":
                                                            { "Ref": "AWS::Region" }
                                                        }
                                                    ]
                                                },
                                                "application_name": { "Ref": "ApplicationName" },
                                                "boto3_version": { "Ref": "Boto3Version" },
                                                "branch": { "Ref": "Branch" },
                                                "build": { "Ref": "Build" },
                                                "environment": { "Ref": "Environment" },
                                                "mongo_version": { "Ref": "MongoVersion" },
                                                "pymongo_version": { "Ref": "PyMongoVersion" },
                                                "vpc_name": { "Ref": "VpcName" },
                                                "threatstack_activation_url": {
                                                    "Fn::If": [
                                                        "IsInfDevelopmentEnvironment",
                                                        { "Ref": "ThreatStackActivationUrl" }, "none"
                                                    ]
                                                },
                                                "region": { "Ref": "AWS::Region" }
                                            },
                                            "owner": "root",
                                            "group": "root",
                                            "mode": "000444"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "AMITemplateInstance": {
                        "Metadata": {
                            "AWS::CloudFormation::Init": {
                                "create_image": {
                                    "files": {
                                        "/var/sophos/cookbooks/attributes.json": {
                                            "content": {},
                                            "context": {
                                                "ami_bucket":                 { "Ref": "AMIBucket" },
                                                "ami_destination_regions":    { "Ref": "AMIDestinationRegions" },
                                                "ami_launch_permissions":     { "Ref": "AMILaunchPermissions" },
                                                "application_name":           { "Ref": "ApplicationName" },
                                                "availability_zone":          {
                                                    "Fn::Select": [
                                                        { "Ref": "AvailabilityZoneIndex" },
                                                        { "Fn::GetAZs": { "Ref": "AWS::Region" } }
                                                    ]
                                                },
                                                "boto3_version":              { "Ref": "Boto3Version" },
                                                "branch":                     { "Ref": "Branch" },
                                                "build":                      { "Ref": "Build" },
                                                "environment":                { "Ref": "Environment" },
                                                "mongo_version":              { "Ref": "MongoVersion" },
                                                "pymongo_version":            { "Ref": "PyMongoVersion" },
                                                "region":                     { "Ref": "AWS::Region" },
                                                "threatstack_activation_url": {
                                                    "Fn::If": [
                                                        "IsInfDevelopmentEnvironment",
                                                        { "Ref": "ThreatStackActivationUrl" },
                                                        "none"
                                                    ]
                                                },
                                                "vpc_name":                   { "Ref": "VpcName" }
                                            },
                                            "owner":   "root",
                                            "group":   "root",
                                            "mode":    "000444"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            """,
            width=pp_cf.DEFAULT_WIDTH,
            squeeze=True)

    def test_insert_copyright(self):
        self.check_format(
            """
            {
            }
            """,
            """
            {
                "Metadata": {
                    "Copyright": [
                        "Copyright 2015, Sophos Limited. All rights reserved.",
                        "",
                        "'Sophos' and 'Sophos Anti-Virus' are registered trademarks of",
                        "Sophos Limited and Sophos Group.  All other product and company",
                        "names mentioned are trademarks or registered trademarks of their",
                        "respective owners."
                    ]
                }
            }
            """,
            copyright=True,
            year=2015,
            squeeze=True)

    def test_cloudfront_attribute_order(self):
        self.check_format(
            """
            {
                "Resources": {
                    "CloudFrontDistribution": {
                        "Type": "AWS::CloudFront::Distribution",
                        "Properties": {
                            "DistributionConfig": {
                                "DefaultCacheBehavior": {
                                    "AllowedMethods": {
                                        "Fn::If": [
                                            "AllowWriteMethods",
                                            [ "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT" ],
                                            [ "GET", "HEAD" ]
                                        ]
                                    },
                                    "ForwardedValues": { "QueryString": false },
                                    "TargetOriginId": "origin",
                                    "TrustedSigners": {
                                        "Fn::If": [
                                            "TrustedSignersSpecified",
                                            { "Ref": "TrustedSigners" },
                                            { "Ref": "AWS::NoValue" }
                                        ]
                                    },
                                    "ViewerProtocolPolicy": "https-only"
                                },
                                "Origins": [{
                                    "DomainName": {
                                        "Fn::Join": [ "", [
                                            { "Ref": "OriginBucket" },
                                            ".s3.amazonaws.com"
                                        ]]
                                    },
                                    "Id": "origin",
                                    "OriginPath": {
                                        "Fn::If": [
                                            "OriginPathSpecified",
                                            { "Ref": "OriginPath" },
                                            { "Ref": "AWS::NoValue" }
                                        ]
                                    },
                                    "S3OriginConfig": {
                                        "OriginAccessIdentity": {
                                            "Fn::If": [
                                                "OriginAccessIdentityUserSpecified",
                                                {
                                                    "Fn::Join": [ "", [
                                                        "origin-access-identity/cloudfront/",
                                                        { "Ref": "OriginAccessIdentityUser" }
                                                    ]]
                                                },
                                                { "Ref": "AWS::NoValue" }
                                            ]
                                        }
                                    }
                                }]
                            }
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "CloudFrontDistribution": {
                        "Type": "AWS::CloudFront::Distribution",
                        "Properties": {
                            "DistributionConfig": {
                                "DefaultCacheBehavior": {
                                    "TargetOriginId": "origin",
                                    "AllowedMethods": {
                                        "Fn::If": [
                                            "AllowWriteMethods",
                                            [
                                                "DELETE",
                                                "GET",
                                                "HEAD",
                                                "OPTIONS",
                                                "PATCH",
                                                "POST",
                                                "PUT"
                                            ],
                                            [
                                                "GET",
                                                "HEAD"
                                            ]
                                        ]
                                    },
                                    "ForwardedValues": { "QueryString": false },
                                    "TrustedSigners": {
                                        "Fn::If": [
                                            "TrustedSignersSpecified",
                                            { "Ref": "TrustedSigners" },
                                            { "Ref": "AWS::NoValue" }
                                        ]
                                    },
                                    "ViewerProtocolPolicy": "https-only"
                                },
                                "Origins": [{
                                    "Id": "origin",
                                    "DomainName": {
                                        "Fn::Join": [ "", [
                                            { "Ref": "OriginBucket" },
                                            ".s3.amazonaws.com"
                                        ]]
                                    },
                                    "OriginPath": {
                                        "Fn::If": [
                                            "OriginPathSpecified",
                                            { "Ref": "OriginPath" },
                                            { "Ref": "AWS::NoValue" }
                                        ]
                                    },
                                    "S3OriginConfig": {
                                        "OriginAccessIdentity": {
                                            "Fn::If": [
                                                "OriginAccessIdentityUserSpecified",
                                                {
                                                    "Fn::Join": [ "", [
                                                        "origin-access-identity/cloudfront/",
                                                        { "Ref": "OriginAccessIdentityUser" }
                                                    ]]
                                                },
                                                { "Ref": "AWS::NoValue" }
                                            ]
                                        }
                                    }
                                }]
                            }
                        }
                    }
                }
            }
            """,
            width=pp_cf.DEFAULT_WIDTH,
            squeeze=True)

    def test_security_group_keys(self):
        self.check_format(
            """
            {
                "Resources": {
                    "BastionSecurityGroup": {
                        "Type": "AWS::EC2::SecurityGroup",
                        "Properties": {
                            "GroupDescription": "Bastion security group",
                            "SecurityGroupEgress": [{
                                "CidrIp": "0.0.0.0/0",
                                "FromPort": "8",
                                "IpProtocol": "icmp",
                                "ToPort": "8"
                            }, {
                                "CidrIp": "0.0.0.0/0",
                                "FromPort": "80",
                                "IpProtocol": "tcp",
                                "ToPort": "80"
                            }, {
                                "CidrIp": "0.0.0.0/0",
                                "FromPort": "443",
                                "IpProtocol": "tcp",
                                "ToPort": "443"
                            }],
                            "SecurityGroupIngress": [{
                                "CidrIp": "198.144.101.0/24",
                                "FromPort": "22",
                                "IpProtocol": "tcp",
                                "ToPort": "22"
                            }],
                            "Tags": [{
                                "Key": "Name",
                                "Value": {
                                    "Fn::Join": [ ":", [
                                        { "Ref": "VpcName" },
                                        "bastion"
                                    ]]
                                }
                            }],
                            "VpcId": { "Ref": "Vpc" }
                        }
                    },

                    "SecurityGroupBastionIngressFromBastion": {
                        "Properties": {
                            "GroupId": { "Ref": "SecurityGroupBastion" },
                            "IpProtocol": "tcp",
                            "FromPort": "22",
                            "ToPort": "22",
                            "SourceSecurityGroupId": { "Ref": "SecurityGroupBastion" }
                        },
                        "Type": "AWS::EC2::SecurityGroupIngress"
                    },

                    "SecurityGroupBastionEgressToBastion": {
                        "Properties": {
                            "GroupId": { "Ref": "SecurityGroupBastion" },
                            "IpProtocol": "tcp",
                            "FromPort": "22",
                            "ToPort": "22",
                            "DestinationSecurityGroupId": { "Ref": "SecurityGroupBastion" }
                        },
                        "Type": "AWS::EC2::SecurityGroupEgress"
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "BastionSecurityGroup": {
                        "Type": "AWS::EC2::SecurityGroup",
                        "Properties": {
                            "GroupDescription": "Bastion security group",
                            "SecurityGroupEgress": [{
                                "IpProtocol": "icmp",
                                "CidrIp": "0.0.0.0/0",
                                "FromPort": "8",
                                "ToPort": "8"
                            }, {
                                "IpProtocol": "tcp",
                                "CidrIp": "0.0.0.0/0",
                                "FromPort": "80",
                                "ToPort": "80"
                            }, {
                                "IpProtocol": "tcp",
                                "CidrIp": "0.0.0.0/0",
                                "FromPort": "443",
                                "ToPort": "443"
                            }],
                            "SecurityGroupIngress": [{
                                "IpProtocol": "tcp",
                                "CidrIp": "198.144.101.0/24",
                                "FromPort": "22",
                                "ToPort": "22"
                            }],
                            "Tags": [{
                                "Key": "Name",
                                "Value": {
                                    "Fn::Join": [ ":", [
                                        { "Ref": "VpcName" },
                                        "bastion"
                                    ]]
                                }
                            }],
                            "VpcId": { "Ref": "Vpc" }
                        }
                    },

                    "SecurityGroupBastionEgressToBastion": {
                        "Type": "AWS::EC2::SecurityGroupEgress",
                        "Properties": {
                            "GroupId": { "Ref": "SecurityGroupBastion" },
                            "IpProtocol": "tcp",
                            "FromPort": "22",
                            "ToPort": "22",
                            "DestinationSecurityGroupId": { "Ref": "SecurityGroupBastion" }
                        }
                    },

                    "SecurityGroupBastionIngressFromBastion": {
                        "Type": "AWS::EC2::SecurityGroupIngress",
                        "Properties": {
                            "GroupId": { "Ref": "SecurityGroupBastion" },
                            "IpProtocol": "tcp",
                            "FromPort": "22",
                            "ToPort": "22",
                            "SourceSecurityGroupId": { "Ref": "SecurityGroupBastion" }
                        }
                    }
                }
            }
            """,
            squeeze=True)

    def test_resource_order_alpha(self):
        self.check_format(
            """
            {
                "Resources": {
                    "A": {},
                    "Z": {},
                    "M": {}
                }
            }
            """,
            """
            {
                "Resources": {
                    "A": {},

                    "M": {},

                    "Z": {}
                }
            }
            """,
            order=pp_cf.ORDER_ALPHA,
            squeeze=True)

    def test_resource_order_source(self):
        self.check_format(
            """
            {
                "Resources": {
                    "A": {},
                    "Z": {},
                    "M": {}
                }
            }
            """,
            """
            {
                "Resources": {
                    "A": {},

                    "Z": {},

                    "M": {}
                }
            }
            """,
            order=pp_cf.ORDER_SOURCE,
            squeeze=True)

    def test_policy_document_order(self):
        self.check_format(
            """
            {
                "Resources": {
                    "BakerRequestQueuePolicy": {
                        "Type": "AWS::SQS::QueuePolicy",
                        "Properties": {
                            "PolicyDocument": {
                                "Id": "SomeId",
                                "Statement": [{
                                    "Sid": "SomeSid",
                                    "Action": "sqs:SendMessage",
                                    "Condition": {
                                        "ArnEquals": { "aws:SourceArn": { "Ref": "BakerRequestTopic" } }
                                    },
                                    "Effect": "Allow",
                                    "Principal": { "AWS": "*" },
                                    "Resource": { "Fn::GetAtt": [ "BakerRequestQueue", "Arn" ] }
                                }],
                                "Version": "2012-10-17"
                            },
                            "Queues": [{ "Ref": "BakerRequestQueue" }]
                        }
                    }
                }
            }
            """,
            """
            {
                "Resources": {
                    "BakerRequestQueuePolicy": {
                        "Type": "AWS::SQS::QueuePolicy",
                        "Properties": {
                            "PolicyDocument": {
                                "Id": "SomeId",
                                "Version": "2012-10-17",
                                "Statement": [{
                                    "Sid": "SomeSid",
                                    "Effect": "Allow",
                                    "Action": "sqs:SendMessage",
                                    "Principal": { "AWS": "*" },
                                    "Resource": { "Fn::GetAtt": [ "BakerRequestQueue", "Arn" ] },
                                    "Condition": {
                                        "ArnEquals": { "aws:SourceArn": { "Ref": "BakerRequestTopic" } }
                                    }
                                }]
                            },
                            "Queues": [{ "Ref": "BakerRequestQueue" }]
                        }
                    }
                }
            }
            """,
            width=pp_cf.DEFAULT_WIDTH,
            squeeze=True)

if __name__ == "__main__":
    unittest.main()
