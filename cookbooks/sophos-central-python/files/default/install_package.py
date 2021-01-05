#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.


import optparse
import os
import subprocess


def parse_command_line():
    parser = optparse.OptionParser(usage="%prog PACKAGE")

    options, args = parser.parse_args()

    if len(args) < 1:
        parser.error("missing required package argument")

    if len(args) > 1:
        parser.error("too many arguments")

    return options, args


def install_package(package):
    os.chdir(package)

    package_name = os.path.basename(package)

    command = [
        "python", "setup.py", "install",
        "--install-scripts=/usr/bin",
        "--record", "/var/log/python-install-%s.list" % package_name,
    ]

    subprocess.check_call(command)


def _main():
    _, packages = parse_command_line()

    cwd = os.getcwd()
    for package in packages:
        install_package(package)
        os.chdir(cwd)


if __name__ == "__main__":
    _main()
