#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the check_cloudformation utility.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

# TODO: Add additional tests to cover deeper inspection of template and parameter files.
# TODO: Add additional tests to cover weather_wizard=True option.
# TODO: Add additional tests to cover files containing invalid JSON.

from checkers import CloudFormationChecker

import cStringIO
import json
import unittest


class CloudFormationCheckerTest(unittest.TestCase):
    """
    Unit tests for CloudFormationChecker.
    """

    def __init__(self, *args, **kwargs):
        super(self.__class__, self).__init__(*args, **kwargs)
        self._reset()

    def _reset(self, checker=None, passed=True, errors=[]):
        self.checker = checker
        self.passed = passed
        self.errors = errors

    def check(self, t=None, p=None):
        """
        Check a single invocation of CloudFormationChecker.check_all().
        """

        self._reset()

        c = CloudFormationChecker()

        if t is not None:
            c.set_template_data(json.loads(t), "t.json")

        if p is not None:
            c.set_parameter_data(json.loads(p), "p.json")

        io = cStringIO.StringIO()
        c.set_error_stream(io)

        passed = c.check_all()
        errors = io.getvalue().splitlines()

        self._reset(checker=c, passed=passed, errors=errors)

    def test_no_data(self):
        self.check()

        self.assertEqual(self.errors, [])
        self.assertTrue(self.passed)

    # Test template data that is just a single item.

    def test_template_is_bool(self):
        self.check(t="true")

        self.assertIn("t.json: root has type bool, expected one of ['dict']", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    def test_template_is_dict(self):
        self.check(t="{}")

        self.assertIn("t.json: root is missing required key AWSTemplateFormatVersion", self.errors)
        self.assertIn("t.json: root is missing required key Description", self.errors)
        self.assertIn("t.json: root is missing required key Metadata", self.errors)
        self.assertIn("t.json: root is missing required key Resources", self.errors)
        self.assertEqual(len(self.errors), 4)
        self.assertFalse(self.passed)

    def test_template_is_list(self):
        self.check(t="[]")

        self.assertIn("t.json: root has type list, expected one of ['dict']", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    def test_template_is_num(self):
        self.check(t="123")

        self.assertIn("t.json: root has type int, expected one of ['dict']", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    def test_template_is_str(self):
        self.check(t='""')

        self.assertIn("t.json: root has type unicode, expected one of ['dict']", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    # Test parameter data that is just a single item.

    def test_parameter_is_bool(self):
        self.check(p="false")

        self.assertIn("p.json: root has type bool, expected one of ['list']", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    def test_parameter_is_dict(self):
        self.check(p="{}")

        self.assertIn("p.json: root has type dict, expected one of ['list']", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    def test_parameter_is_list(self):
        self.check(p="[]")

        self.assertEqual(self.errors, [])
        self.assertTrue(self.passed)

    def test_parameter_is_num(self):
        self.check(p="3.141592")

        self.assertIn("p.json: root has type float, expected one of ['list']", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    def test_parameter_is_str(self):
        self.check(p='""')

        self.assertIn("p.json: root has type unicode, expected one of ['list']", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    # Other tests.

    def test_minimal_template_data(self):
        self.check(t="""
        {
            "AWSTemplateFormatVersion": "2010-09-09",
            "Description": "",
            "Metadata": {
                "Copyright": [ "Copyright 2016 ...", "respective owners." ],
                "Comments": [ { "Ref": "Description" }, " ", "The template follows ...", "number of instances.", "" ]
            },
            "Resources": {}
        }
        """, p="[]")

        self.assertEqual(self.errors, [])
        self.assertTrue(self.passed)

    def test_invalid_template_key(self):
        self.check(t="""
        {
            "AWSTemplateFormatVersion": "2010-09-09",
            "Description": "",
            "Metadata": {
                "Copyright": [ "Copyright 2016 ...", "respective owners." ],
                "Comments": [ { "Ref": "Description" }, " ", "The template follows ...", "number of instances.", "" ]
            },
            "Resources": {},
            "Bogus": 123
        }
        """, p="[]")

        self.assertIn("t.json: root contains an entry with invalid key Bogus", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    def test_invalid_template_key_data_type(self):
        self.check(t="""
        {
            "AWSTemplateFormatVersion": "2010-09-09",
            "Description": "",
            "Metadata": true,
            "Parameters": 3.14,
            "Mappings": ["bogus"],
            "Conditions": ["bogus"],
            "Resources": {},
            "Conditions": "bogus"
        }
        """)

        self.assertIn("t.json: root['Metadata'] has type bool, expected one of ['dict']", self.errors)
        self.assertIn("t.json: root['Parameters'] has type float, expected one of ['dict']", self.errors)
        self.assertIn("t.json: root['Mappings'] has type list, expected one of ['dict']", self.errors)
        self.assertIn("t.json: root['Conditions'] has type unicode, expected one of ['dict']", self.errors)
        self.assertEqual(len(self.errors), 4)
        self.assertFalse(self.passed)

    # Parameter consistency tests.

    def test_valid_parameter_with_default(self):
        self.check(t="""
        {
            "AWSTemplateFormatVersion": "2010-09-09",
            "Description": "",
            "Metadata": {
                "Copyright": [ "Copyright 2016 ...", "respective owners." ],
                "Comments": [ { "Ref": "Description" }, " ", "The template follows ...", "number of instances.", "" ]
            },
            "Parameters": {
                "Parameter1": {
                    "Description": "",
                    "Type": "String",
                    "Default": ""
                }
            },
            "Resources": {}
        }
        """, p="[]")

        self.assertEqual(len(self.errors), 0)
        self.assertTrue(self.passed)

    def test_valid_parameter_without_default(self):
        self.check(t="""
        {
            "AWSTemplateFormatVersion": "2010-09-09",
            "Description": "",
            "Metadata": {
                "Copyright": [ "Copyright 2016 ...", "respective owners." ],
                "Comments": [ { "Ref": "Description" }, " ", "The template follows ...", "number of instances.", "" ]
            },
            "Parameters": {
                "Parameter1": {
                    "Description": "",
                    "Type": "String"
                }
            },
            "Resources": {}
        }
        """, p="[]")

        self.assertIn("p.json: parameters list is missing required key Parameter1", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

    def test_valid_parameter_with_match(self):
        self.check(t="""
        {
            "AWSTemplateFormatVersion": "2010-09-09",
            "Description": "",
            "Metadata": {
                "Copyright": [ "Copyright 2016 ...", "respective owners." ],
                "Comments": [ { "Ref": "Description" }, " ", "The template follows ...", "number of instances.", "" ]
            },
            "Parameters": {
                "Parameter1": {
                    "Description": "",
                    "Type": "String",
                    "Default": ""
                }
            },
            "Resources": {}
        }
        """, p="""
        [{
            "ParameterKey": "Parameter1",
            "ParameterValue": ""
        }]
        """)

        self.assertEqual(len(self.errors), 0)
        self.assertTrue(self.passed)

    def test_extra_parameter(self):
        self.check(t="""
        {
            "AWSTemplateFormatVersion": "2010-09-09",
            "Metadata": {
                "Copyright": [ "Copyright 2016 ...", "respective owners." ],
                "Comments": [ { "Ref": "Description" }, " ", "The template follows ...", "number of instances.", "" ]
            },
            "Description": "",
            "Resources": {}
        }
        """, p="""
        [{
            "ParameterKey": "Parameter1",
            "ParameterValue": ""
        }]
        """)

        self.assertIn("t.json: template parameters is missing required key Parameter1", self.errors)
        self.assertEqual(len(self.errors), 1)
        self.assertFalse(self.passed)

if __name__ == "__main__":
    unittest.main()
