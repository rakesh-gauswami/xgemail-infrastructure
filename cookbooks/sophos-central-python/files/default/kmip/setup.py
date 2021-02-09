# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

from setuptools import setup


setup(
    name="kmip",
    description="KMIP client implementation",

    # This will always get stored fresh on an instance, no need to change this.
    # Or maybe append a post-release tag, e.g. "-" + str(time.time()).
    version="0.1",

    # Need either author/author_email or maintainer/maintainer_email.
    author="Sophos, Inc.",
    author_email="cloud-inf@sophos.com",

    # Consult MANIFEST.in for list of data files to include in the package.
    # https://pythonhosted.org/setuptools/setuptools.html#including-data-files
    include_package_data=False,

    # List packages needed to run.
    # https://pythonhosted.org/setuptools/setuptools.html#declaring-dependencies
    install_requires=["PyKMIP", "gcc", "git", "zlib-devel", "bzip2-devel", "readline-devel", "python-devel", "libffi-devel", "openssl-devel", "sqlite-devel", "patch"],

    # List packages to install, relative to this file.
    packages=["kmip"],

    # List scripts to install, relative to this file.
    scripts=[],

    # Install as source code, not as zipfile.
    # https://pythonhosted.org/setuptools/setuptools.html#setting-the-zip-safe-flag
    zip_safe=False)
