#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# This script contains common utility methods related to disk tasks

import subprocess
import os
from notadirectoryexception import NotADirectoryException

def is_directory_empty(directory_path):
    """An efficient way of determining if a directory is empty or not. Use
    this rather than os.listdir() if the directory you are checking potentially
    has a large number of files in it.
    """

    exception_string = 'Provided argument <{0}> is not a directory'.format(
        directory_path
    )

    if directory_path is None:
        raise NotADirectoryException(exception_string)

    if not os.path.isdir(directory_path):
        raise NotADirectoryException(exception_string)

    is_empty_path_command = 'find {0} -maxdepth 0 -empty'.format(directory_path)

    output = subprocess.Popen(
        is_empty_path_command,
        shell=True,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Get standard out and error
    (stdout, stderr) = output.communicate()

    # if the directoy is empty, it is returned as a string
    empty_directory = stdout.decode()

    if empty_directory:
        return True
    return False
