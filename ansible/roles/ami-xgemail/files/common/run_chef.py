#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Run chef in a standard way, specifying recipes.
"""

import optparse
import os
import subprocess
import time


# Default directory where cookbooks are to be installed.
DEFAULT_CHEF_REPO_DIR = "/var/chef/chef-repo"


# Default directory for writing log files.
DEFAULT_LOG_DIR = "/var/log/sophos"


def parse_command_line():
    parser = optparse.OptionParser(usage="%prog [options] [recipe(s)]")

    parser.add_option(
            "-a", "--attrsfile", metavar="PATH", default=None,
            help="Attributes file (JSON format)")

    parser.add_option(
            "-c", "--chef-dir", metavar="DIR", default=DEFAULT_CHEF_REPO_DIR,
            help="Chef repo directory")

    parser.add_option(
            "-d", "--log-dir", metavar="DIR", default=DEFAULT_LOG_DIR,
            help="Directory where log files should be written")

    parser.add_option(
            "-l", "--log-suffix", metavar="SUFFIX", default=None,
            help="Suffix for log file name")

    options, recipes = parser.parse_args()

    return options, recipes


def _main():
    options, recipes = parse_command_line()

    config_path = os.path.join(options.chef_dir, ".chef/client.rb")

    if not os.path.isdir(options.log_dir):
        subprocess.check_call(["mkdir", "-p", options.log_dir])

    log_filename = time.strftime("chef-%Y%m%d.%H%M%S")
    if options.log_suffix is not None:
        log_filename += "."
        log_filename += options.log_suffix
    log_filename += ".log"

    log_path = os.path.join(options.log_dir, log_filename)

    command = [
        "chef-client",
        "-z",
        "--no-color",
        "-c", config_path,
        "-l", "debug",
        "-L", log_path,
    ]

    if options.attrsfile is not None:
        command.extend(["-j", options.attrsfile])

    if len(recipes) > 0:
        command.extend(["-o", ",".join(recipes)])

    subprocess.check_call(command)


if __name__ == "__main__":
    _main()
