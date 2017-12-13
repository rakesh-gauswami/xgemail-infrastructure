#!/usr/bin/python

# Sophos Anti-Virus OEM package download script
#
# Requirements: python 2.x; wget 1.x
#
# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import os
import re
import sys
import zipfile
import optparse

# The wget tool must be installed to use this script.
# Set its location here if not in the default path.
WGET_COMMAND = 'wget'

__VERSION__  = '1.00'
USER_AGENT   = 'SophosSAVDownload/%s wget/1.0' % __VERSION__

BASE_URL     = 'http://downloads.sophos.com/sophos/products/full/OEM/SAVi'
WINDOWS_PATH = '/current/win32/'
UNIX_PATH    = '/current/unix/'
DATA_PATH    = '/data/'
VDL_PACKAGE  = 'vdl.zip'
IDE_PACKAGE  = 'ide_%s.zip'

USAGE        = """Usage: %prog [options]

Will download the latest Sophos Anti-Virus OEM engine/libsavi, VDL, and IDE
packages to the directory specified with -o. If the latest version of any
of the packages is already downloaded and in that directory, it won't be
downloaded again, so you should not empty the directory between runs.

This script won't extract or install the packages. We recommend that you
extract them and then perform a binary diff with your currently installed
set to determine the changes required for your products.

Example: %prog -p engine-package-name.tar -o sav-packages

The GNU wget tool must be installed and in the path to use this script.
You can set proxy configuration in ~/.wgetrc - see "info wget"."""


# Read the version file in the data package and return the version number.
# datafile: path to the data package zip.
def get_data_version(datafile):
    
    datazip = zipfile.ZipFile(datafile)
    version = datazip.read('virusDataVersion.txt')
    datazip.close()    
    # remove trailing newline
    return re.sub(r'\s', '', version)


# Download the supplied URL using wget.
# output: directory in which to place downloaded files.
def download_if_updated(url, output, user, password):
    
    cmd = WGET_COMMAND
    if user:     cmd += ' --user=%s'     % user
    if password: cmd += ' --password=%s' % password
    # enable timestamping so it doesn't download if the latest version is already downloaded
    cmd += ' --user-agent="%s (u=\\"%s\\")" --timestamping --directory-prefix="%s" "%s"' % (USER_AGENT, user, output, url)
    #print 'Running %s' % cmd
    exitcode = os.system(cmd)
    return exitcode == 0


# Download the specified engine package.
# package: name of the engine package to download.
# output: directory in which to place downloaded files.
def download_engine(package, output, user, password):
    
    if re.search('win', package):
        url = BASE_URL + WINDOWS_PATH + package
    else:
        url = BASE_URL + UNIX_PATH + package
    
    return download_if_updated(url, output, user, password)


# Download the data and IDE packages.
# output: directory in which to place downloaded files.
def download_data(output, user, password):
    
    ret = download_if_updated(BASE_URL + DATA_PATH + VDL_PACKAGE, output, user, password)
    if ret:
        # get version number from data package, and download corresponding IDE package
        data_version = get_data_version(os.path.join(output, VDL_PACKAGE))
        ret = download_if_updated(BASE_URL + DATA_PATH + (IDE_PACKAGE % data_version), output, user, password)
    return ret


# Download IDEs only, don't update main virus data if already present (but download if not).
# output: directory in which to place downloaded files.
def download_ides(output, user, password):
    
    datapkg = os.path.join(output, VDL_PACKAGE)
    ret = os.path.exists(datapkg)
    
    if not ret:
        ret = download_if_updated(BASE_URL + DATA_PATH + VDL_PACKAGE, output, user, password)
        
    if ret:
        # get version number from data package, and download corresponding IDE package
        data_version = get_data_version(datapkg)
        ret = download_if_updated(BASE_URL + DATA_PATH + (IDE_PACKAGE % data_version), output, user, password)
    return ret


if __name__ == '__main__':
    
    parser = optparse.OptionParser(usage = USAGE)
    parser.add_option("-p", "--package", action="append",     default=None,  help="Name of engine package to download. Can be specified more than once to download multiple packages. Required unless using -d or -i only.")
    parser.add_option("-a", "--all",     action="store_true", default=False, help="Download all components, equivalent to -d -e (default).")
    parser.add_option("-e", "--engine",  action="store_true", default=False, help="Download engine/libsavi only.")
    parser.add_option("-d", "--data",    action="store_true", default=False, help="Download VDL (main virus data) and IDEs (data updates) only.")
    parser.add_option("-i", "--ides",    action="store_true", default=False, help="Download IDEs only. If the VDL package is already present don't update it, but download if not present.")
    parser.add_option("-o", "--output",  action="store",      default=".",   help="Directory to save packages to. Will be created if necessary. If not specified, will use the current directory.")
    parser.add_option("-U", "--user",    action="store",      default=None,  help="")
    parser.add_option("-P", "--password",action="store",      default=None,  help="Sophos download credentials user name and password.")

    (opts, args) = parser.parse_args()
    
    # download all by default
    if not opts.engine and not opts.data and not opts.ides:
        opts.all = True
        
    # download engine package if requested
    if opts.engine or opts.all:
        
        if opts.package == None:
            print "Error: -p (--package) must be specified unless downloading data only."
            sys.exit(1)
        
        for pkg in opts.package:
            if download_engine(pkg, opts.output, opts.user, opts.password):
                print "*** Successfully got latest engine package %s ***\n" % pkg
            else:
                print "*** Error: failed to download engine package %s ***\n" % pkg

    # download data and IDE packages if requested
    if opts.data or opts.all:
        if download_data(opts.output, opts.user, opts.password):
            print "*** Successfully got latest data packages ***\n"
        else:
            print "*** Error: failed to download data packages ***\n"

    # download IDEs only, don't update main virus data if already present (but download if not)
    elif opts.ides:
        if download_ides(opts.output, opts.user, opts.password):
            print "*** Successfully got latest data packages ***\n"
        else:
            print "*** Error: failed to download data packages ***\n"
