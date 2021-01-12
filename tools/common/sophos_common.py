#!/usr/bin/env python
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# common/common.py: common functionality

import botocore
import contextlib
import itertools
import logging
import os
import subprocess
import sys
import time


def msg(message):
    print >>sys.stderr, "%s: %s" % (
            os.path.basename(sys.argv[0]), message.strip())


def die(message):
    print >>sys.stderr, "%s: %s" % (
            os.path.basename(sys.argv[0]), message.strip())
    sys.exit(1)


@contextlib.contextmanager
def cd(path):
    cwd = os.getcwd()
    try:
        os.chdir(path)
        yield
    finally:
        os.chdir(cwd)


@contextlib.contextmanager
def logtime(operation):
    # TODO: use logging.info instead of print.
    # For some reason that doesn't seem to work when run in a subprocess.
    print time.strftime("%F %T"), "INFO ENTER", operation
    start_time = time.time()
    yield
    seconds = "%.3f" % (time.time() - start_time)
    print time.strftime("%F %T"), "INFO LEAVE", operation, "took", seconds, "seconds"


def call(*args, **kwargs):
    return subprocess.call(args, **kwargs)


def check_call(*args, **kwargs):
    return subprocess.check_call(args, **kwargs)


def check_output(*args, **kwargs):
    return subprocess.check_output(args, **kwargs)


def aws_metadata(path):
    url = "http://169.254.169.254/latest/meta-data/%s" % path
    cmd = "wget --quiet --timeout=5 --tries=1 -O- %s" % url
    argv = cmd.split()
    return subprocess.check_output(argv)


def aws_availability_zone():
    return aws_metadata("placement/availability-zone")


def aws_instance_id():
    return aws_metadata("instance-id")


def aws_region():
    # Just remove trailing character from availability zone.
    return aws_metadata("placement/availability-zone")[:-1]


def boto3_call_with_retry(method, *args, **kwargs):
    method_name = "%s.%s.%s" % (
            method.im_self.__module__,
            method.im_self.__class__.__name__,
            method.im_func.__name__)

    max_minutes = 15
    deadline = time.time() + max_minutes * 60

    for attempt in itertools.count():
        try:
            logging.info(
                    "CALL %s args=%r kwargs=%r", method_name, args, kwargs)
            return method(*args, **kwargs)
        except botocore.exceptions.ClientError as e:
            logging.info("ClientError %r", e.response)
            if e.response["Error"]["Code"] != "RequestLimitExceeded":
                raise
            delay_seconds = 2 ** attempt
            if time.time() + delay_seconds > deadline:
                raise
            time.sleep(delay_seconds)


def boto3_check(method, *args, **kwargs):
    response = boto3_call_with_retry(method, *args, **kwargs)
    assert response["ResponseMetadata"]["HTTPStatusCode"] == 200
    return response


def next_available_device():
    chars = map(lambda o: chr(o), range(ord("a"), ord("z") + 1))
    for c in chars:
        device = "/dev/xvd" + c
        if os.path.exists(device):
            continue
        return device
    return None


def find_partition_device(device):
    # Give the OS time to catch up.
    while not os.path.exists(device):
        time.sleep(2)

    lsblk_output = subprocess.check_output(
            ["/bin/lsblk",
             "--noheadings",
             "--ascii",
             "--list",
             "--output", "TYPE,NAME",
             device])

    for line in lsblk_output.splitlines():
        device_type, device_name = line.split(None, 1)
        if device_type == "part":
            return "/dev/" + device_name

    die("device '%s' has no partitions" % device)
