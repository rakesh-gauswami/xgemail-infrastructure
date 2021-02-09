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


setup(
    name="sophos",
    description="Sophos Central common python code",

    # This will always get stored fresh on an instance, no need to change this.
    # Or maybe append a post-release tag, e.g. "-" + str(time.time()).
    version="0.1",

    # Need either author/author_email or maintainer/maintainer_email.
    author="Sophos, Inc.",
    author_email="central-guild-inf@sophos.com",

    # Consult MANIFEST.in for list of data files to include in the package.
    # https://pythonhosted.org/setuptools/setuptools.html#including-data-files
    include_package_data = False,

    # List packages needed to run.
    # https://pythonhosted.org/setuptools/setuptools.html#declaring-dependencies
    install_requires=[],

    # List packages to install, relative to this file.
    packages=["sophos"],

    # List scripts to install, relative to this file.
    scripts=[],

    # Install as source code, not as zipfile.
    # https://pythonhosted.org/setuptools/setuptools.html#setting-the-zip-safe-flag
    zip_safe=False)
