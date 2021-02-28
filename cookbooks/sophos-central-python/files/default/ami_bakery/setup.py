# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import os

from setuptools import setup
from setuptools.command.install import install


class CustomInstallCommand(install):
    def run(self):
        # setuptools uses old-style python class, which doesn't honor
        # the "super" keyword.
        install.run(self)

        # Install the ami_bakery service script if possible (e.g. not on a Mac).
        # setuptools.setup() doesn't provide a mechanism to install a file
        # in an arbitrary location, so we have to implement it ourselves.
        if os.path.isdir("/etc/init.d"):
            self.copy_file("./init.d/ami_bakery", "/etc/init.d/ami_bakery")


setup(
    name="ami_bakery",
    description="AMI bakery service",

    # This will always get stored fresh on an instance, no need to change this.
    # Or maybe append a post-release tag, e.g. "-" + str(time.time()).
    version="0.1",

    # Need either author/author_email or maintainer/maintainer_email.
    author="Sophos, Inc.",
    author_email="central-guild-inf@sophos.com",

    # Use custom install command to install init.d service script.
    cmdclass={
        "install": CustomInstallCommand
    },

    # Consult MANIFEST.in for list of data files to include in the package.
    # https://pythonhosted.org/setuptools/setuptools.html#including-data-files
    include_package_data = True,

    # List packages needed to run.
    # https://pythonhosted.org/setuptools/setuptools.html#declaring-dependencies
    install_requires=[],

    # List packages to install, relative to this file.
    packages=["ami_bakery"],

    # List scripts to install, relative to this file.
    scripts=["bin/ami_bakery"],

    # Install as source code, not as zipfile.
    # https://pythonhosted.org/setuptools/setuptools.html#setting-the-zip-safe-flag
    zip_safe=False)
