#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
# 
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Test fake object for use when testing.
"""

# Import test module FIRST to make sure there are no dependencies.
import sophos.fake_object

import unittest

class TestException(Exception):
    pass

class FakeObjectTest(unittest.TestCase):
    def test_empty_object(self):
        fo = sophos.fake_object.FakeObject("empty")
        self.assertTrue(fo.empty())

        # AttributeError gets raised here because we never identify
        # 'anything' as a method.
        with self.assertRaises(AttributeError):
            fo.anything()

    def test_no_args(self):
        fo = sophos.fake_object.FakeObject()
        self.assertTrue(fo.empty())

        fo.queue_result(42, "foo")
        self.assertFalse(fo.empty())

        self.assertEqual(fo.foo(), 42)
        self.assertTrue(fo.empty())

        fo.queue_result("hello, world!", "foo")
        fo.queue_result("goodbye, world!", "foo")
        self.assertFalse(fo.empty())

        self.assertEqual(fo.foo(), "hello, world!")
        self.assertFalse(fo.empty())
        self.assertEqual(fo.foo(), "goodbye, world!")
        self.assertTrue(fo.empty())

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo()

        fo.queue_result(("1st", "2nd"), "foo_tuple")
        r1, r2 = fo.foo_tuple()
        self.assertEqual(r1, "1st")
        self.assertEqual(r2, "2nd")

    def test_different_args(self):
        fo = sophos.fake_object.FakeObject()
        self.assertTrue(fo.empty())

        fo.queue_result("1st", "foo", "first")
        fo.queue_result("2nd", "foo", "second")
        fo.queue_result("3rd", "foo", which="third", password="sEcReT")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo("third")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo(which="third")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo("sEcReT", which="third")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo(which="third", password="pUbLic")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo(which="third", credential="sEcReT")

        self.assertEqual(fo.foo(password="sEcReT", which="third"), "3rd")
        self.assertEqual(fo.foo("first"), "1st")
        self.assertEqual(fo.foo("second"), "2nd")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo("first")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo("second")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo("third")

        with self.assertRaises(sophos.fake_object.UnexpectedCallError):
            fo.foo("fourth")

    def test_context_manager(self):
        with sophos.fake_object.fake_object() as fo:
            pass

        with self.assertRaises(sophos.fake_object.UnexpectedContextExitError):
            with sophos.fake_object.fake_object() as fo:
                fo.queue_result(42, "foo")

        with sophos.fake_object.fake_object("ec2") as ec2:
            ec2.queue_result("ec2", "whoami")
            with sophos.fake_object.fake_object("s3") as s3:
                s3.queue_result("s3", "whoami")
                self.assertEqual(ec2.whoami(), "ec2")
                self.assertEqual(s3.whoami(), "s3")

        with self.assertRaises(sophos.fake_object.UnexpectedContextExitError) as cm:
            with sophos.fake_object.fake_object("ec2") as ec2:
                with sophos.fake_object.fake_object("s3") as s3:
                    ec2.queue_result(42, "foo")
        self.assertIn("'ec2'", cm.exception.message)

        with self.assertRaises(sophos.fake_object.UnexpectedContextExitError) as cm:
            with sophos.fake_object.fake_object("ec2") as ec2:
                with sophos.fake_object.fake_object("s3") as s3:
                    s3.queue_result(42, "foo")
        self.assertIn("'s3'", cm.exception.message)

    def test_fake_exception(self):
        with self.assertRaises(TestException) as cm:
            te = TestException("this is my exception")
            feh = sophos.fake_object.FakeExceptionHolder(te)
            feh.raise_exception()
        self.assertEqual(cm.exception.message, "this is my exception")

    def test_queued_exception(self):
        with self.assertRaises(TestException) as cm:
            with sophos.fake_object.fake_object() as fo:
                te = TestException("this is my exception")
                feh = sophos.fake_object.FakeExceptionHolder(te)
                fo.queue_result(feh, "foo")
                fo.foo()
        self.assertEqual(cm.exception.message, "this is my exception")

    def test_mix_of_queued_results_and_exception(self):
        with sophos.fake_object.fake_object() as fo:
            fo.queue_result(123, "foo")
            fo.queue_result(sophos.fake_object.FakeExceptionHolder(KeyError("foo")), "foo")
            fo.queue_result("after an exception", "foo")

            self.assertEqual(fo.foo(), 123)

            with self.assertRaises(KeyError):
                fo.foo()

            self.assertEqual(fo.foo(), "after an exception")

            with self.assertRaises(sophos.fake_object.UnexpectedCallError):
                fo.foo()

if __name__ == "__main__":
    unittest.main()
