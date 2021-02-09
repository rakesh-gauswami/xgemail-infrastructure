#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Fake object for use when testing.

The FakeObject class is useful when you want to mock an object that might
have the same method called multiple times behind one line of test code,
with each call potentially returning different results.  The mock module
does not seem to provide a way to handle this, it can just set a constant
return value using code like this:

    mock_object.method_name.result = 42

This is not sufficiently expressive to let us mock calls to, for example,
a boto3 client object where we might call the describe_instance_status method
multiple times in a loop to gather paged results.

There is a hack using a side_effect function that can achieve this,
but the resulting test code is rather ugly.  See here:

    http://www.voidspace.org.uk/python/mock/examples.html#multiple-calls-with-different-effects

Using FakeObject is much clearer:

    # Create a fake object.
    # The name argument is optional.
    ec2 = FakeObject("ec2")

    fo.queue_result(
        { ... return value from first call to describe_instance_status ... },
        "describe_instance_status",
        MaxResults=1
    )

    fo.queue_result(
        { ... return value from second call to describe_instance_status ... },
        "describe_instance_status",
        NextToken=...,
        MaxResults=1
    )

    # Create test object which takes a boto3 ec2 client object as a parameter:
    test_object = TestObject(ec2)

    # Test it.
    results = test_object.get_instance_statuses()
    self.assertEqual(results, ...)

Even better, we can creat the FakeObject in a with statement so that an
exception will be raised if we don't consume all queued return values.
This helps make sure that a unit test doesn't pass accidentally
without making the expected calls to the fake object.

    with fake_object.fake_object() as ec2:
        ec2.queue_result(...)
        ec2.queue_result(...)
        test_object = TestObject(ec2)
        results = test_object.get_instance_statuses()
        self.assertEqual(results, ...)

We can also simulate exceptions by queueing a fake_object.FakeExceptionHolder
object that contains the exception we want to raise:

    with fake_object.fake_object() as ec2:
        e = MyException("this is my exception")
        feh = fake_object.FakeExceptionHolder(e)
        ec2.queue_result(feh, "foo")
        with self.assertRaises(MyException) as cm:
            ec2.foo()
        self.assertEqual(cm.exception.message, "this is my exception")
"""

import contextlib
import json

class FakeObjectError(Exception):
    """
    Base class for exceptions defined in this module.
    """
    pass

class UnexpectedCallError(FakeObjectError):
    """
    Error raised when a method is called on a FakeObject instance
    and there is no queued response for that method with the given
    arguments.
    """
    def __init__(self, fo, method_name, args, kwargs):
        message = "FakeObject '%s' method '%s' unexpectedly called with args %s and kwargs %s" % (
                fo.name(), method_name, args, kwargs)
        super(UnexpectedCallError, self).__init__(message)
        self.message = message

class UnexpectedContextExitError(FakeObjectError):
    """
    Error raised when a context manager created by the fake_object()
    function closes without all queued methods having been called.
    """
    def __init__(self, fo):
        message = "FakeObject '%s' closed before all queued return values have been returned." % fo.name()
        super(UnexpectedContextExitError, self).__init__(message)
        self.message = message

class FakeExceptionHolder(object):
    """
    Holder for an exception to be queued for raising when a method is called.
    """

    def __init__(self, exception):
        self._exception = exception

    def raise_exception(self):
        raise self._exception

class FakeObject(object):
    """
    A fake object for use when testing.
    """

    def __init__(self, name=None):
        """
        Create a new FakeObject instance with no queued method calls.
        """
        if name is None:
            name = "anonymous"

        # Object name, used when raising exceptions.
        self._name = name

        # Two-level dict mapping methods to arguments to result queues.
        self._methods_arguments_results = {}

    @staticmethod
    def _arguments_as_str(*args, **kwargs):
        return json.dumps({"args": args, "kwargs": kwargs}, sort_keys=True)

    def empty(self):
        """
        Return True if there are no queued method calls.
        """
        for arguments_results in self._methods_arguments_results.values():
            for results in arguments_results.values():
                if len(results) > 0:
                    return False
        return True

    def name(self):
        """
        Return the name of this object (used in exceptions).
        """
        return self._name

    def queue_result(self, result, method_name, *args, **kwargs):
        """
        Arrange for 'result' to be returned when 'method_name' is called
        on this object with the given arguments.

        Each call to this method is good for only a single invocation of
        'method_name'.  This allows users to simulate things like pagination
        of results where the same call returns different values with each
        invocation.

        Example:

            # Create a fake object.
            fo = FakeObject()

            # Make the next call to method foo() return a string.
            fo.queue_result("hello, world!", "foo")
            
            # Call foo() on the fake object and print the result.
            print "result:", fo.foo()

            # We only queued one invocation so calling foo again raises an exception.
            fo.foo()

        Use a tuple to simulate multiple return values from a single call:

            # Create a fake object.
            fo = FakeObject()

            # Make the next call to method foo return 2 values, a string and a number.
            fo.queue_result(("a", 1), "foo")

            # Call foo() on the fake object and save the return values in separate
            # variables.
            r1, r2 = fo.foo()
        """

        arguments = self._arguments_as_str(*args, **kwargs)

        if method_name not in self._methods_arguments_results:
            self._methods_arguments_results[method_name] = {}

            def method_proxy(*a, **k):
                args = self._arguments_as_str(*a, **k)
                try:
                    ret = self._methods_arguments_results[method_name][args].pop(0)
                except (KeyError, IndexError):
                    raise UnexpectedCallError(self, method_name, a, k)

                if isinstance(ret, FakeExceptionHolder):
                    ret.raise_exception()
                else:
                    return ret

            setattr(self, method_name, method_proxy)

        if arguments not in self._methods_arguments_results[method_name]:
            self._methods_arguments_results[method_name][arguments] = []

        self._methods_arguments_results[method_name][arguments].append(result)


@contextlib.contextmanager
def fake_object(name=None):
    """
    Return a new FakeObject instance in a context manager that raises an
    UnexpectedContextExitError exception if the context manager is closed
    before all queued method calls have been called.

    In case you're wondering, this will NOT break unit tests that raise
    exceptions within the body of the context manager.  For example,
    given the following unit test method:

        def test_x(self):
            with fake_object.fake_object() as fo:
                fo.queue_result(None, "foo")
                self.assertEqual(2 + 2, 5)

    the exception raised by the call to self.assertEqual() will propagate
    out of the context manager before the FakeObject instance can be checked
    for uncalled methods.
    """

    fo = FakeObject(name)

    yield fo

    if not fo.empty():
        raise UnexpectedContextExitError(fo)
