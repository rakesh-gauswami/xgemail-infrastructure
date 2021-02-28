#!/usr/bin/env python
# vim: autoindent expandtab shiftwidth=4 filetype=python

# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Test sophos.common module.
"""

# Import test module FIRST to make sure there are no dependencies.
import sophos.common

import cStringIO
import StringIO
import sys
import unittest


class ParseDurationTest(unittest.TestCase):
    """Test sophos.common.parse_duration function."""

    def test_invalid_argument_type(self):
        with self.assertRaises(TypeError):
            sophos.common.parse_duration(None)

        with self.assertRaises(TypeError):
            sophos.common.parse_duration(123)

        with self.assertRaises(TypeError):
            sophos.common.parse_duration(-0.789)

        with self.assertRaises(TypeError):
            sophos.common.parse_duration([])

        with self.assertRaises(TypeError):
            sophos.common.parse_duration({})

        with self.assertRaises(TypeError):
            sophos.common.parse_duration(object())

    def test_invalid_duration_string(self):
        with self.assertRaises(ValueError):
            sophos.common.parse_duration("")

        # No number
        with self.assertRaises(ValueError):
            sophos.common.parse_duration("s")

        # No suffix
        with self.assertRaises(ValueError):
            sophos.common.parse_duration("123")

        # Invalid suffix
        with self.assertRaises(ValueError):
            sophos.common.parse_duration("3x")

        # Invalid case for suffix
        with self.assertRaises(ValueError):
            sophos.common.parse_duration("3S")

    def test_valid_duration_string(self):
        # Simple case
        self.assertEqual(sophos.common.parse_duration("13s"), 13)

        # Float number
        self.assertEqual(sophos.common.parse_duration("1.5m"), 90)

        # Negative number
        self.assertEqual(sophos.common.parse_duration("-.25h"), -900)

        # Leading whitespace
        self.assertEqual(sophos.common.parse_duration(" 2d"), 2 * 86400)

        # Embedded whitespace
        self.assertEqual(sophos.common.parse_duration(" 3 w"), 21 * 86400)

        # Trailing whitespace and scientific notation
        self.assertEqual(sophos.common.parse_duration(" 0.5e2 y \n"), 50 * 365 * 86400)


class PrintRowsTest(unittest.TestCase):
    """Test sophos.common.print_rows function."""

    def check(self, rows, expected, **kwargs):
        fp = StringIO.StringIO()

        sophos.common.print_rows(rows, file=fp, **kwargs)

        if isinstance(expected, basestring):
            self.assertEqual(fp.getvalue(), expected)
        else:
            output_lines = fp.getvalue().splitlines()
            for i in range(0, min(len(output_lines), len(expected))):
                self.assertEqual(output_lines[i], expected[i])

    def test_empty_list(self):
        self.check([], "")

    def test_single_data_row(self):
        rows = [[1, 2.3, "4.5.6", "last column, with spaces!"]]
        self.check(rows, "1  2.3  4.5.6  last column, with spaces!\n")

    def test_single_title_row(self):
        # First two columns are numeric, so right-aligned.
        # Remain columns are non-numeric, so left-aligned.
        rows = [
            ["h1", "h2", "h3", "h4"],
            [1, 2.3, "4.5.6", "last column, with spaces!"],
        ]
        expected = [
            "h1| h2|h3   |h4",
            " 1|2.3|4.5.6|last column, with spaces!",
        ]
        self.check(rows, expected, sep="|")

    def test_special_effects(self):
        rows = [
            ["h1", "h2", "h3", "h4"],
            "-",
            [1, 2.3, None, "last column, with spaces!"],
            ["--", 99.12, "slartibartfast!", "fghj"],
            ["--", 199.8, "slartibartfast!", "fghj"],
            None,
            ["10%", "", "", "enough???"],
        ]
        expected = [
            " h1      h2  h3               h4",
            "---  ------  ---------------  -------------------------",
            "  1    2.30                   last column, with spaces!",
            " --   99.12  slartibartfast!  fghj",
            " --  199.80  slartibartfast!  fghj",
            "",
            "10%                           enough???",
        ]
        self.check(rows, expected)

    def test_practical_example(self):
        data_rows = [
            [1, 2, 3, 4, 5],
            [2, 4, 6, 8, 10],
        ]

        header = [ "c%d" % (i + 1) for i in range(len(data_rows[0])) ]

        header.append("SUM")
        for row in data_rows:
            row.append(sum(row))

        rows = [ header, "-" ] + data_rows

        expected = [
            "c1  c2  c3  c4  c5  SUM",
            "--  --  --  --  --  ---",
            " 1   2   3   4   5   15",
            " 2   4   6   8  10   30",
        ]

        self.check(rows, expected)


class RedirectStderrTest(unittest.TestCase):
    """Test sophos.common.redirect_stderr function."""

    def test_stringio(self):
        fp = StringIO.StringIO()
        with sophos.common.redirect_stderr(fp):
            print >> sys.stderr, "able was i ere i saw elba"
        self.assertEqual(fp.getvalue(), "able was i ere i saw elba\n")

    def test_cstringio(self):
        fp = cStringIO.StringIO()
        with sophos.common.redirect_stderr(fp):
            print >> sys.stderr, "able was i ere i saw elba"
        self.assertEqual(fp.getvalue(), "able was i ere i saw elba\n")


class RedirectStdoutTest(unittest.TestCase):
    """Test sophos.common.redirect_stdout function."""

    def test_stringio(self):
        fp = StringIO.StringIO()
        with sophos.common.redirect_stdout(fp):
            print "able was i ere i saw elba"
        self.assertEqual(fp.getvalue(), "able was i ere i saw elba\n")

    def test_cstringio(self):
        fp = cStringIO.StringIO()
        with sophos.common.redirect_stdout(fp):
            print "able was i ere i saw elba"
        self.assertEqual(fp.getvalue(), "able was i ere i saw elba\n")


class StatsAccumulatorTest(unittest.TestCase):
    """Test sophos_common.StatsAccumulator class."""

    def check(self, values, **kwargs):
        stats = sophos.common.StatsAccumulator()

        for v in values:
            stats.add(v)

        if "num" in kwargs:
            self.assertEqual(stats.num(), kwargs["num"])

        if "sum" in kwargs:
            self.assertEqual(stats.sum(), kwargs["sum"])

        if "sos" in kwargs:
            self.assertEqual(stats.sos(), kwargs["sos"])

        if "min" in kwargs:
            self.assertEqual(stats.min(), kwargs["min"])

        if "max" in kwargs:
            self.assertEqual(stats.max(), kwargs["max"])

        if "mean" in kwargs:
            self.assertAlmostEqual(stats.mean(), kwargs["mean"], delta=kwargs.get("delta"))

        if "variance" in kwargs:
            self.assertAlmostEqual(stats.variance(), kwargs["variance"], delta=kwargs.get("delta"))

        if "stddev" in kwargs:
            self.assertAlmostEqual(stats.stddev(), kwargs["stddev"], delta=kwargs.get("delta"))

    def test_empty_input(self):
        self.check([], num=0, sum=0, sos=0, min=None, max=None, mean=None, variance=None, stddev=None)

    def test_single_input_value(self):
        x = 12.531
        self.check([x], num=1, sum=x, sos=x*x, min=x, max=x, mean=x, variance=0, stddev=0)

    def test_two_input_values(self):
        x = 60
        y = 80
        self.check([x, y], num=2, sum=x + y, sos=x*x + y*y, min=x, max=y, mean=0.5 * (x + y), variance=100, stddev=10)

    def test_umpteen_positive_input_values(self):
        n = 100
        xs = range(1, n + 1)
        self.check(xs, num=n, sum=0.5*n*(n+1), min=1, max=n, mean=0.5*(n+1))

    def test_umpteen_negative_input_values(self):
        n = 100
        xs = map(lambda x: -x, range(1, n + 1))
        self.check(xs, num=n, sum=-0.5*n*(n+1), min=-n, max=-1, mean=-0.5*(n+1))

    def test_percentile_did_not_ask_to_retain_data(self):
        stats = sophos.common.StatsAccumulator()
        with self.assertRaises(sophos.common.StatsAccumulator.Error):
            stats.percentile(50)

    def test_percentile_empty_input(self):
        stats = sophos.common.StatsAccumulator(True)
        with self.assertRaises(IndexError):
            stats.percentile(0)

    def check_percentiles(self, values, **kwargs):
        stats = sophos.common.StatsAccumulator(True)

        for v in values:
            stats.add(v)

        for (percentile, expected) in sorted(kwargs.items()):
            self.assertTrue(percentile.startswith("p"))
            percentile = float(percentile[1:])
            self.assertEqual(stats.percentile(percentile), expected)

    def test_percentile_single_value(self):
        self.check_percentiles([123], p0=123, p50=123, p100=123)

    def test_percentile_two_values(self):
        self.check_percentiles([123, 124], p0=123, p50=123.5, p100=124)
        self.check_percentiles([123, 125], p0=123, p50=124, p100=125)
        self.check_percentiles([0, 1], p0=0, p25=0.25, p50=0.5, p75=0.75, p100=1)


if __name__ == "__main__":
    unittest.main()
