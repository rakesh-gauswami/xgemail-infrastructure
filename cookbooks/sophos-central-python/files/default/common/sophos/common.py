#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Common code for use in Sophos Central servers.
"""

import contextlib
import gzip
import json
import logging
import logging.handlers
import math
import numbers
import os
import pwd
import signal
import subprocess
import sys
import time


# Possible locations for chef attributes file.
# On MongoDB instances the file is called instance-attributes.json
# to distinguish it from the instance-attributes.json file created
# during AMI building.
CHEF_ATTRIBUTES_FILE_PATHS = [
    "/var/sophos/cookbooks/instance-attributes.json",
    "/var/sophos/cookbooks/attributes.json",
    "/var/chef/roles/base.json",
]


# Default location for log files.
LOG_DIR = "/var/log"


# Default format for log files.
LOG_FORMAT = "%(asctime)s %(process)d %(levelname)s %(name)s %(message)s"


def wrap_main(main):
    """
    Call provided `main` function with proper signal handling.
    """

    # Suppress stack trace that occurs when output from this command to a pipe
    # is not consumed because the process on the other side of the pipe exited.
    # This commonly occurs when piping output through a paging program like
    # 'more' or 'less'.
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)

    # Suppress stack trace on termination by Ctrl-C.
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(128 + signal.SIGINT)


def program_basename(program_path=None):
    """
    Return basename of program_path (default sys.argv[0]), stripped of file extensions.
    """

    if program_path is None:
        program_path = sys.argv[0]

    return os.path.splitext(os.path.basename(program_path))[0]


def configure_logging(
        dirpath=None, filename=None, stream=None,
        logger=None, level=logging.INFO, botoLevel=logging.WARNING,
        formatter=None, **kwargs):
    """
    Setup application logging, specifying stream and/or filename.

    If dirpath and/or filename is not None, log to a rotating file handler
    configured with kwargs.

    If stream is not None, log to the given stream.

    You may specify both a filename and a stream if you like, for example to log
    to a file and to sys.stdout or sys.stderr.

    By default, sets log level for all AWS boto modules to WARNING to reduce log noise.
    To disable this change set botoLevel=None.
    """

    handlers = []

    if dirpath is None and filename is None:
        logpath = None
    elif dirpath is not None:
        logpath = os.path.join(dirpath, program_basename() + ".log")
    elif filename is not None:
        logpath = filename if os.path.isabs(filename) else os.path.join(os.getcwd(), filename)
    else:
        logpath = os.path.join(dirpath, filename)

    if logpath is not None:
        handlers.append(logging.handlers.RotatingFileHandler(logpath, **kwargs))

    if stream is not None:
        handlers.append(logging.StreamHandler(stream))

    if logger is None:
        logger = logging.getLogger()

    if formatter is None:
        formatter = logging.Formatter(LOG_FORMAT)

    for h in handlers:
        h.setLevel(level)
        h.setFormatter(formatter)
        logger.addHandler(h)

    logger.setLevel(level)

    logger.propagate = False

    if botoLevel is not None:
        for module in ["botocore", "boto", "boto3"]:
            logging.getLogger(module).setLevel(botoLevel)


def fatal(fmt, *args, **kwargs):
    """
    Log message with CRITICAL severity, then exit.

    To override the exit value, which defaults to 1, set the exit
    keyword argument, e.g.

        fatal("failed: %s", reason, exit=5)

    To pass current exception information, set the exc_info keyword
    argument, e.g.

        fatal("failed: %s", reason, exc_info=1)
    """

    logging.fatal(fmt, *args, **kwargs)
    sys.exit(kwargs.get("exit", 1))


def debug(fmt, *args, **kwargs):
    """
    Log message with DEBUG severity.

    To pass current exception information, set the exc_info keyword
    argument, e.g.

        debug("failed: %s", reason, exc_info=1)
    """

    logging.debug(fmt, *args, **kwargs)


def info(fmt, *args, **kwargs):
    """
    Log message with INFO severity.

    To pass current exception information, set the exc_info keyword
    argument, e.g.

        info("failed: %s", reason, exc_info=1)
    """

    logging.info(fmt, *args, **kwargs)


def become_user(username):
    """
    Change user and group id to that of the specified user.
    """

    pw = pwd.getpwnam(username)
    os.setgid(pw.pw_gid)
    os.setuid(pw.pw_uid)


@contextlib.contextmanager
def cd(path):
    """
    Temporarily change directory.

    Example:
        with sophos.common.cd("/tmp"):
            ... do stuff here
    """

    cwd = os.getcwd()
    try:
        os.chdir(path)
        yield
    finally:
        os.chdir(cwd)


PARSE_DURATION_SUFFIXES = [
    # suffix, multiplier
    ( "s", 1 ),
    ( "m", 60 ),
    ( "h", 3600 ),
    ( "d", 86400 ),
    ( "w", 7 * 86400 ),
    ( "y", 365 * 86400 ),
]

def parse_duration(s):
    """
    Parse duration string, return number of seconds or raise an exception.

    Duration strings consist of a number followed by a suffix, e.g. "30s" or "13.5h".

    We support the following suffixes:
        s: seconds
        m: minutes
        h: hours
        d: days
        w: weeks
        y: years (365 days, we ignore leap years)
    """

    if not isinstance(s, basestring):
        raise TypeError("expected a string")

    stripped = s.strip()

    for suffix, multiplier in PARSE_DURATION_SUFFIXES:
        if stripped.endswith(suffix):
            return multiplier * float(stripped[0:-1])

    raise ValueError("invalid duration")


class SafeJsonEncoder(json.JSONEncoder):
    """
    Encoder suitable for serializing ANYTHING to JSON.

    Use like this:
        json.dumps(o, cls=sophos.common.SafeJsonEncoder)
    """

    def default(self, o):  # pylint: disable=method-hidden
        try:
            return json.JSONEncoder.default(self, o)
        except TypeError:
            return repr(o)


def pretty_json_dumps(obj, cls=SafeJsonEncoder):
    """
    Call json.dumps with the usual parameters.
    """

    return json.dumps(
            obj,
            cls=cls,
            ensure_ascii=True,
            indent=4,
            separators=(',', ': '),
            sort_keys=True)


# The parameter names file and sep are taken from python3's print function.
# Not worrying about end and flush parameters for now.
def print_rows(rows, file=sys.stdout, sep="  "):
    """
    Print rows of data in straight columns.

    Formatting is encoded in the rows:

    * If a row entry is None, a blank line will be printed.

    * If a row entry is a string, its first character will be repeated to
      generate a dividing line within each column.

    * Otherwise a row entry is assumed to be a sequence of data cells.

    Column widths and alignment are determined by the data.

    Numeric columns are aligned right, text columns are aligned left.
    Columns are considered numeric if they contain any numeric data cells.
    """

    def stringify(data, digits=None):
        if data is None:
            return ""

        if isinstance(data, numbers.Number) and digits is not None:
            stringfmt = "%." + str(digits) + "f"
            return stringfmt % data

        return str(data)

    # Pre-process data once to compute alignment parameters.
    # fmtmod is used directly in the format string to align left or right.
    digits = []
    fmtmod = []
    for row in rows:
        if row is None:
            continue
        if isinstance(row, basestring):
            continue
        for i, data in enumerate(row):
            while i >= len(digits):
                digits.append(0)
            while i >= len(fmtmod):
                fmtmod.append("-")
            if isinstance(data, numbers.Number):
                digits[i] = max(digits[i], len((str(data) + ".").split(".")[1]))
                fmtmod[i] = ""

    # Pre-process data a second time to compute column widths.
    # We have to do this in a separate pass because the width is dependent
    # on the values in the digits array, which depends on all the data.
    widths = []
    for row in rows:
        if row is None:
            continue
        if isinstance(row, basestring):
            continue
        for i, data in enumerate(row):
            while i >= len(widths):
                widths.append(0)
            stringval = stringify(data, digits=digits[i])
            widths[i] = max(widths[i], len(stringval))

    # Now we can properly format the data.
    for row in rows:
        if row is None:
            print >> file, ""
            continue

        if isinstance(row, basestring):
            print >> file, sep.join([row[0] * widths[i] for i in range(len(widths))])
            continue

        cells = []
        for i, data in enumerate(row):
            stringval = stringify(data, digits=digits[i])
            stringfmt = "%" + fmtmod[i] + str(widths[i]) + "s"
            cells.append(stringfmt % stringval)

        print >> file, sep.join(cells).rstrip()


def read_chef_attributes():
    """
    Return dictionary of chef configuration settings read from attributes.json file.
    """

    for path in CHEF_ATTRIBUTES_FILE_PATHS:
        if os.path.exists(path):
            with open(path) as fp:
                d = json.load(fp)
                # The attributes file read on instances deployed by as_template.json
                # has the attributes we care about on level below the root of the
                # JSON structure.
                d = d.get("default_attributes", d)
                return d

    raise Exception("cannot find chef attributes file, checked %r" % CHEF_ATTRIBUTES_FILE_PATHS)


@contextlib.contextmanager
def redirect_stderr(new_target):
    """
    Temporarily redirect sys.stderr to new_target.

    Example:
        f = StringIO.StringIO()
        with sophos.common.redirect_stderr(f):
            help(pow)
        s = f.getvalue()

    Because this function modifies the global sys.stderr object it is unsuitable
    for use in threaded applications and in libraries, but is very helpful for
    test code.
    """

    old_stderr = sys.stderr
    try:
        old_stderr.flush()
        sys.stderr = new_target
        yield
    finally:
        sys.stderr.flush()
        sys.stderr = old_stderr


@contextlib.contextmanager
def redirect_stdout(new_target):
    """
    Temporarily redirect sys.stdout to new_target.

    Example:
        f = StringIO.StringIO()
        with sophos.common.redirect_stdout(f):
            help(pow)
        s = f.getvalue()

    Because this function modifies the global sys.stdout object it is unsuitable
    for use in threaded applications and in libraries, but is very helpful for
    test code.
    """

    old_stdout = sys.stdout
    try:
        old_stdout.flush()
        sys.stdout = new_target
        yield
    finally:
        sys.stdout.flush()
        sys.stdout = old_stdout


def run(argv):
    """
    Run the command specified in ``argv``.  Return standard output.
    """

    assert isinstance(argv, list)

    logging.debug("running: %s" % argv)

    pipe = subprocess.Popen(
            argv,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            close_fds=True,
            universal_newlines=True)

    out, err = pipe.communicate()

    for line in out.splitlines():
        logging.debug("out: " + line)

    for line in err.splitlines():
        logging.debug("err: " + line)

    logging.debug("ret: %d" % pipe.returncode)

    if pipe.returncode > 0:
        raise Exception("failed, command '%s' exited with status %d" % (
            argv, pipe.returncode))

    if pipe.returncode < 0:
        raise Exception("failed, command '%s' terminated by signal %d" % (
            argv, -pipe.returncode))

    return out


class RunResults(object):
    """
    Results from the run_advanced function.
    """

    def __init__(self, argv, stdout, stderr, pid, returncode):
        self.argv = argv
        self.stdout = stdout
        self.stderr = stderr
        self.pid = pid
        self.returncode = returncode


def run_advanced(argv):
    """
    Run the command specified in ``argv``.  Return a RunResults object.
    """

    assert isinstance(argv, list)

    logging.debug("running: %s" % argv)

    pipe = subprocess.Popen(
            argv,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            close_fds=True,
            universal_newlines=True)

    out, err = pipe.communicate()

    for line in out.splitlines():
        logging.debug("out: " + line)

    for line in err.splitlines():
        logging.debug("err: " + line)

    logging.debug("ret: %d" % pipe.returncode)

    return RunResults(argv, out, err, pipe.pid, pipe.returncode)


@contextlib.contextmanager
def smart_open(path, mode="r"):
    """
    Return gzip.open(path, mode) or open(path, mode), according to filename extension.
    """

    fp = None
    try:
        fp = gzip.open(path, mode) if path.endswith(".gz") else open(path, mode)
        yield fp
    finally:
        if fp is not None:
            fp.close()


class StatsAccumulator(object):
    """
    Simple statistics accumulator.

    Getting basic statistics:
        import sophos.common
        stats = sophos.common.StatsAccumulator()
        for x in range(1, 101):
            stats.add(x)
        print "num:", stats.num()           # prints 100
        print "min:", stats.min()           # prints 1.0
        print "max:", stats.max()           # prints 100.0
        print "mean:", stats.mean()         # prints 50.5
        print "variance:", stats.variance() # prints 833.25
        print "stddev:", stats.stddev()     # prints 28.8660700477

    Getting percentiles:
        import sophos.common
        # For percentiles we need to record all observations.
        # This requires extra memory so we have to explicitly enable it.
        stats = sophos.common.StatsAccumulator(True)
        for x in range(1, 101):
            stats.add(x)
        print "median:", stats.percentile(50)       # prints 50.5
        print "95th %ile:", stats.percentile(95)    # prints 95.05
    """

    class Error(Exception):
        pass

    def __init__(self, percentiles=False):
        self._num = 0
        self._sum = 0.0
        self._sos = 0.0
        self._min = None
        self._max = None
        self._percentiles = percentiles
        self._observations = []

    def add(self, v):
        """Add value to accumulator, after coercing it to float."""
        v = float(v)
        self._num += 1
        self._sum += v
        self._sos += v * v
        self._min = v if self._min is None else min(self._min, v)
        self._max = v if self._max is None else max(self._max, v)
        if self._percentiles:
            self._observations.append(v)

    def num(self):
        """Return number of values added."""
        return self._num

    def sum(self):
        """Return sum of values added."""
        return self._sum

    def sos(self):
        """Return sum of squares of values added."""
        return self._sos

    def min(self):
        """Return minimum of values added."""
        return self._min

    def max(self):
        """Return maximum of values added."""
        return self._max

    def mean(self):
        """Return mean of values added."""
        if self._num <= 0:
            return None
        else:
            return self._sum / self._num

    def variance(self):
        """Return population variance of values added."""
        if self._num <= 0:
            return None
        else:
            # Naive formula for estimating variance of a population.
            # See https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance for alternatives.
            return max(0.0, (self._sos - (self._sum * self._sum) / self._num) / self._num)

    def stddev(self):
        """Return population standard deviation of values added."""
        if self._num <= 0:
            return None
        else:
            return self.variance() ** 0.5

    def percentile(self, q):
        """Return the q'th percentile of recorded observations using linear interpolation."""

        if not self._percentiles:
            raise StatsAccumulator.Error("Did not request percentiles in constructor so did not retain data needed to calculate them.")

        # Compute target index by scaling percentile to index range.

        ix = 0.01 * q * (self.num() - 1)

        # Compute indexes for values we interpolate between.

        lo = int(math.floor(ix))
        hi = int(math.ceil(ix))

        # Return the interpolated value between the values at the two indexes.

        self._observations.sort()

        return self._observations[lo] + (ix - lo) * (self._observations[hi] - self._observations[lo])


class Timer(object):
    """
    Record elapsed time for a code block.

    Use like this:

        with sophos.common.Timer() as timer:
            code ...

        logging.info("elapsed time: %f seconds", timer.seconds())
    """

    def __init__(self):
        self.begin = None
        self.end = None

    def __enter__(self):
        self.begin = time.time()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.end = time.time()

    def seconds(self):
        """Return elapsed time as float seconds."""
        return self.end - self.begin
