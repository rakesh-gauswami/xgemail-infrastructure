#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Code to assist with writing tests.
"""

import inspect
import re


def _make_test_method_name(generator_name, n, args):
    """
    Return the name for a generated test method.

    We try to include the arguments passed to the generated method in the
    generated method name to make it easier to see context when a test fails.
    """

    components = [ "test", generator_name, "%03d" % n ]

    # TODO: Replace with an encoding scheme that better handles class objects.
    # We'll get to it when we need it; this will do for now.

    for arg in args:
        component = None

        if arg is None:
            component = "N"
        elif isinstance(arg, str):
            component = "S" + arg
        elif isinstance(arg, unicode):
            component = "U" + repr(arg)
        elif isinstance(arg, int):
            # Replace leading negative sign.
            component = "I" + str(arg).replace("-", "neg")
        elif isinstance(arg, float):
            # Replace leading negative sign.
            # Replace decimal points, both US and European.
            component = "F" + str(arg).replace("-", "neg").replace(".", "p").replace(",", "p")
        else:
            component = "C" + arg.__class__.__name__

        if component is None:
            continue

        component = re.sub(r"[^A-Za-z0-9_]", "", component)

        components.append(component)

    return "_".join(components)


def _make_test_method(check_method, check_args):
    """
    Return new test method from check method and arguments.
    A separate function is necessary because python lacks block scoping
    that would allow generation of distinct methods inside a loop.
    """

    def test_method(self):
        check_method(self, *check_args)

    return test_method


def _generate_test_methods(cls):
    """
    Generate new test methods for the given class using the check method
    and arguments provided by class methods whose names begin with "gen_".
    """

    new_tests = dict()

    members = inspect.getmembers(cls, predicate=inspect.ismethod)
    for generator_name, generator_method in members:
        if generator_name.startswith("gen_"):
            n = 0
            for test_tuple in generator_method():
                n += 1
                check_method, check_args = test_tuple[0], test_tuple[1:]

                test_name = _make_test_method_name(generator_name, n, check_args)
                new_tests[test_name] = _make_test_method(check_method, check_args)

    for test_name, test_method in new_tests.iteritems():
        setattr(cls, test_name, test_method)


class TestGenerator(type):
    """
    Metaclass that generates new test methods for each class that uses it.

    We want to support nosetest-like test case generators but still have access
    to all the unittest assert methods.  To implement this we use a python
    metaclass that finds and executes classmethods whose names begin with "gen_"
    to determine what method to call and what inputs to pass to that method.
    For example:

        class MyTest(unittest.TestCase):
            __metaclass__ = sophos.testing.TestGenerator

            def check_something(self, x, y):
                self.assertTrue(code_being_tested(x, y))

            @classmethod
            def gen_something_tests(cls):
                for x in range(4):
                    for y in range(4):
                        yield cls.check_something, x, y
    """

    def __init__(cls, name, bases, attrs):
        _generate_test_methods(cls)
        super(TestGenerator, cls).__init__(name, bases, attrs)
