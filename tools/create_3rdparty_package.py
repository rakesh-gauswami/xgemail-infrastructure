#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
Create a 3rd-party package file.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

from __future__ import print_function

import abc
import collections
import docker
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import textwrap
import verbatim_option_parser
import zipfile


GENERIC_PACKAGES = [
    {
        'name':  'filebeat',
        'version': '1.2.3',
        'files': [{
            'url': 'https://download.elastic.co/beats/filebeat/filebeat-{version}-x86_64.rpm',
            'sha1_url': 'https://download.elastic.co/beats/filebeat/filebeat-{version}-x86_64.rpm.sha1.txt'
        }]
    },
    {
        'name':  'logstash',
        'version': '1.5.6-1',
        'files': [ {
            'url': 'https://download.elastic.co/logstash/logstash/packages/centos/logstash-{version}.noarch.rpm',
            'sha1_url': 'https://download.elastic.co/logstash/logstash/packages/centos/logstash-{version}.noarch.rpm.sha1.txt'
        }]
    }
]

def parse_command_line(package_file_creators):
    description = textwrap.dedent("""
    Download a third-party package and create a .tar.gz file suitable for
    installation on a server running Amazon Linux.
    """)

    epilog = "Supported packages:\n"
    for creator in package_file_creators:
        name = creator.get_package_name()
        sample_version = creator.get_sample_version()
        epilog += "  %-11s sample version: %s\n" % (name + ":", sample_version)

    for package in GENERIC_PACKAGES:

        epilog += "  %-11s sample version: %s\n" % (package['name'] + ":", package['version'])

    parser = verbatim_option_parser.VerbatimOptionParser(
            usage="usage: %prog [options] PACKAGE VERSION [USERNAME [PASSWORD]]",
            description=description,
            epilog=epilog)

    parser.add_option(
            "-k", action="store_true", dest="keep", default=False,
            help="keep temporary directory instead of deleting it")

    parser.add_option(
            "-s", metavar="PATH", dest="summary", default=None,
            help="write summary file to PATH after success")

    parser.add_option(
            "-t", metavar="PATH", dest="tmpdir", default=None,
            help="use PATH as temporary directory, and don't delete it")

    options, args = parser.parse_args()

    if len(args) < 2:
        parser.error("too few arguments")

    if len(args) > 4:
        parser.error("too many arguments")

    package = args[0]
    version = args[1]
    username = args[2] if len(args) > 2 else None
    password = args[3] if len(args) > 3 else None

    for creator in package_file_creators:
        if package == creator.get_package_name():
            return options, package, version, username, password, creator

    for generic in GENERIC_PACKAGES:
        if package == generic['name']:
            generic['version'] = version
            return options, package, version, username, password, GenericPackageFileCreator(package =  generic)

    parser.error("unsupported package: %s" % package)


def info(message):
    sys.stderr.write(sys.argv[0])
    sys.stderr.write(": ")
    sys.stderr.write(message)
    sys.stderr.write("\n")


def die(message):
    info(message)
    sys.exit(1)


def getcmd(command):
    if os.path.isabs(command):
        if os.path.isfile(command):
            return command

    path = os.environ["PATH"]
    for dirpath in path.split(os.pathsep):
        cmdpath = os.path.join(dirpath, command)
        if os.path.isfile(cmdpath):
            return cmdpath

    return None


def fix_argv(argv):
    command = argv[0]
    fullpath = getcmd(command)
    if fullpath is None:
        die("command not found: %s" % command)
    argv[0] = fullpath


def check_call(argv, **kwds):
    fix_argv(argv)
    info(" ".join(argv))
    return subprocess.check_call(argv, **kwds)


def check_output(argv, **kwds):
    fix_argv(argv)
    info(" ".join(argv))
    return subprocess.check_output(argv, **kwds)


def wget(url, destpath, extra=None):
    # The --progress=dot:mega option increases the size represented by each
    # dot in the progress bar to 64K (not, NOT 1MB), or 3MB per line.
    # The --server-response option just prints the headers sent back
    # in the HTTP response, on the off chance it's useful for debugging.
    wget_command = ["wget", "-O", destpath, "--progress=dot:mega", "--server-response"]
    if extra is not None:
        wget_command.extend(extra)
    wget_command.append(url)
    check_call(wget_command)


def check_md5(download_path, md5_path):
    if getcmd("md5") is None:
        info("no md5 command, cannot verify download integrity")
        return

    actual_md5 = check_output(["md5", download_path]).strip().split()[-1]
    info("actual MD5: %s" % actual_md5)

    with open(md5_path) as fp:
        wanted_md5 = fp.readline().strip().split()[0]
        info("wanted MD5: %s" % wanted_md5)

        if actual_md5 != wanted_md5:
            raise Exception("%s: invalid MD5 hash" % download_path)

def check_sha1(download_path, sha1_path):
    cmd = "sha1sum"
    if getcmd(cmd) is None:
        info("no sha1 command, cannot verify download integrity")
        return

    actual_sha1 = check_output([cmd, download_path]).strip().split()[-1]
    info("actual SHA1: %s" % actual_sha1)

    with open(sha1_path) as fp:
        wanted_sha1 = fp.readline().strip().split()[1]
        info("wanted SHA1: %s" % wanted_sha1)

        if actual_sha1 != wanted_sha1:
            raise Exception("%s: invalid SHA1 hash" % download_path)

def create_tar_gz(basename, arguments):
    package_file = basename + ".tar.gz"
    check_call(["ls","-al"])
    check_call(["tar", "czvf", package_file] + arguments)
    return package_file


# Read the version file in the data package and return the version number.
# datafile: path to the data package zip.
def get_data_version(datafile):

    datazip = zipfile.ZipFile(datafile)
    version = datazip.read('virusDataVersion.txt')
    datazip.close()
    # remove trailing newline
    return re.sub(r'\s', '', version)

def md5sum(filename, blocksize=65536):
    return hash_file(filename, hashlib.md5(), blocksize)

def sha1sum(filename, blocksize=65536):
    return hash_file(filename, hashlib.sha1(), blocksize)

def sha256sum(filename, blocksize=65536):
    return hash_file(filename, hashlib.sha256(), blocksize)

def hash_file(filename, hasher, blocksize=65536):
    with open(filename, "rb") as f:
        for block in iter(lambda: f.read(blocksize), b""):
            hasher.update(block)
    return hasher.hexdigest()

class PackageFileCreator(object):
    """
    Base class for all package creators.
    """

    __metaclass__ = abc.ABCMeta

    ItemFields = ["filename", "url", "wget_options", "sha1_url", "md5_url" ]
    DownloadItem = collections.namedtuple(
            "DownloadItem",
            ItemFields
            )

    DownloadItem.__new__.__defaults__ = ( None, None )

    def __init__(self, *args, **kwargs):
        self.package = None
        self.sample_version = None
        self.major = None
        self.minor = None
        self.micro = None
        self.patch = None
        self.build = None
        self.nano = None
        self.numeric_version = None

    def create_package_file_from_download(self, version, username, password):
        """
        Download the specified version of a package into the current directory.
        Take those package files and create a .tar.gz file from them.
        Return the name of the created .tar.gz file.
        """

        self.set_version(version)
        self.set_username(username)
        self.set_password(password)

        download_items = self.get_download_items()

        for item in download_items:
            wget(item.url, item.filename, item.wget_options)
            if item.sha1_url != None:
                self.get_and_check_sha1(item)


        basename = self.get_package_file_basename()

        prepared_files = self.prepare_files_for_packing(download_items)

        return create_tar_gz(basename, prepared_files)


    def get_and_check_sha1(self,item):
        """
        Retrieve a sha1 file from a url stored in sha1_url, then compare the file against the sha1
        """

        sha1_filename = os.path.basename(item.sha1_url)
        wget(item.sha1_url, sha1_filename, item.wget_options)
        return check_sha1(item.filename, sha1_filename)

    # Interface functions.
    # These all provide a docstring that gets inherited with the method,
    # then call the abstract implementation method.

    def set_version(self, version):
        """
        Set the desired package version.
        """
        self._set_version(version)

    def set_username(self, username):
        """
        Set the desired package username.
        """
        self._set_username(username)

    def set_password(self, password):
        """
        Set the desired package password.
        """
        self._set_password(password)

    def get_download_items(self):
        """
        Return a list of DownloadItem tuples, each referring to a file
        to download, the URL to download from, and any special wget options
        that should be added (e.g. to accept license agreements).
        """
        return self._get_download_items()

    def get_package_file_basename(self):
        """
        Return the basename of the generated package file.
        """
        return self._get_package_file_basename()

    def get_package_name(self):
        """
        Return the name of the package (independent of version).
        """
        return self._get_package_name()

    def prepare_files_for_packing(self, download_items):
        """
        Take the download package files and prepare the files that will be
        stored in the final .tar.gz file.  Return a list of files to tar.
        """
        return self._prepare_files_for_packing(download_items)

    def get_sample_version(self):
        """
        Return a sample version string.
        """
        return self._get_sample_version()

    # Private implementation methods.

    def _set_version(self, version):
        """
        The default implementation assumes semantic versioning (major.minor.patch).
        """

        self.version = version

        # 4 component version string
        m = re.match("^(\d+)\.(\d+)\.(\d+)[-:.](\d+)$", self.version)
        if m:
            self.version_component_count = 4
            self.major = int(m.group(1))
            self.minor = int(m.group(2))
            # create some common aliases
            self.micro = self.patch = int(m.group(3))
            # ditto
            self.nano = self.build = int(m.group(4))
            # this will push up a version string into 00100200300400500, this is useful for detecting newer versions or comparing versions when version string can be
            # a little unstable (ie distro versions, build versions, 3rd party versions on top of upstream versions)
            # this will break down if any single component goes over 999.
            self.numeric_version = (self.major * 1000 ** 4) + (self.minor * 1000 ** 3) + (self.micro * 1000 ** 2) + (self.nano * 100 ** 1)
            # bail out
            return

        m = re.match("^(\d+)\.(\d+)\.(\d+)$", self.version)
        if m:
            self.version_component_count = 3
            self.major = int(m.group(1))
            self.minor = int(m.group(2))
            # create some common aliases
            self.micro = self.patch = int(m.group(3))
            # this will push up a version string into 00100200300400500, this is useful for detecting newer versions or comparing versions when version string can be
            # a little unstable (ie distro versions, build versions, 3rd party versions on top of upstream versions)
            self.numeric_version = (self.major * 1000 ** 4) + (self.minor * 1000 ** 3) + self.micro * 1000 ** 2
            return

        raise ValueError("cannot parse version: '%s'" % version)


    def _set_username(self, username):
        self.username = username

    def _set_password(self, password):
        self.password = password

    @abc.abstractmethod
    def _get_download_items(self):
        pass

    def _get_package_file_basename(self):
        return "%s-%s" % (self.package, self.version)

    def _get_package_name(self):
        return self.package

    def _get_sample_version(self):
        return self.sample_version

    def _prepare_files_for_packing(self, download_items):
        return [item.filename for item in download_items]


class AbstractBaseDirectoryPackageFileCreator(PackageFileCreator):
    def __init__(
        self,
        *args,
        **kwargs
    ):
        super(AbstractBaseDirectoryPackageFileCreator, self).__init__(*args, **kwargs)

    def get_package_directory(self):
        """
        Set the desired package password.
        """
        return self._get_package_directory()

    def _prepare_files_for_packing(self, download_items):

        package_directory = self.get_package_directory()

        os.makedirs(package_directory)

        for item in download_items:
            shutil.move(item.filename, package_directory)

        # Return a list of files to tar up.
        return [package_directory]

    def _get_package_directory(self):
        return self.get_package_file_basename()

class ChefPackageFileCreator(PackageFileCreator):
    """
    Chef Package Creator.  Generates a .tar.gz file containing the required files.

    All information about the actual chef installer is contained in the metadata file
    So we first retrieve this file and then an actual binary from the reference in the
    metadata file
    """

    def __init__(self, *args, **kwargs):
        super(ChefPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "chef"
        self.sample_version = "12.9.41"

    def _get_download_items(self):
        metadata_url = \
            "https://omnitruck-direct.chef.io/stable/chef/metadata?v=%s&p=el&pv=6&m=x86_64" % (
                self.version
            )

        metadata_filename = "%s-metadata.txt" % self.get_package_file_basename()

        items = []
        items.append(self.DownloadItem(metadata_filename, metadata_url, []))
        return items

    def _prepare_files_for_packing(self, download_items):
        metadata_item = download_items[0]

        meta_sha256 = None
        meta_url = None
        meta_version = None

        with open(metadata_item.filename) as f:
            for line in f:
                key, value = line.strip().split(None, 1)

                if key == "sha256":
                    meta_sha256 = value
                elif key == "url":
                    meta_url = value
                elif key == "version":
                    meta_version = value

        if meta_sha256 is None:
            raise Exception(
                    "%s: Invalid metadata at <%s>, no sha256 hash provided" % (
                        self.get_package_file_basename(),
                        metadata_item.url
                    )
                )
        if meta_url is None:
            raise Exception(
                    "%s: Invalid metadata at <%s>, no url provided" % (
                        self.get_package_file_basename(),
                        metadata_item.url
                    )
                )
        if meta_version is None:
            raise Exception(
                    "%s: Invalid metadata at <%s>, no version provided" % (
                        self.get_package_file_basename(),
                        metadata_item.url
                    )
                )

        if meta_version != self.version:
            raise Exception(
                    "%s: metadata at <%s> has different version: EXPECTED(%s), ACTUAL(%s)" % (
                        self.get_package_file_basename(),
                        metadata_item.url,
                        self.version,
                        meta_version
                    )
                )

        chef_rpm_filename = os.path.basename(meta_url)

        wget(meta_url, chef_rpm_filename, [])

        # Verify rpm's sha256 sum
        actual_sha256 = sha256sum(chef_rpm_filename)

        if meta_sha256 != actual_sha256:
            raise Exception(
                    "%s: Invalid sha256: EXPECTED(%s), ACTUAL(%s)" % (
                        chef_rpm_filename,
                        meta_sha256,
                        actual_sha256
                    )
                )

        package_directory = self.get_package_file_basename()

        os.makedirs(package_directory)

        shutil.move(chef_rpm_filename, package_directory)

        # Return a list of files to tar up.
        return [package_directory]


class CyrenPackageFileCreator(PackageFileCreator):
    """
    Cyren Anti Spam Package Creator.  Generates a .tar.gz file containing the required files.
    """

    def __init__(self, *args, **kwargs):
        super(CyrenPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "ctasd"
        self.sample_version = "5.00.0085"

    def _get_download_items(self):

        url = "ftp://ftp.ctmail.com/ctasd/Release/%s/" % self.version
        url += "%s-%s.1-linux-x86_64.tar.gz" % (self.package, self.version)

        filename = os.path.basename(url)

        wget_options = [
            "--user=%s" % self.username,
            "--password=%s" % self.password,
        ]

        return [self.DownloadItem(filename, url, wget_options)]


    def _prepare_files_for_packing(self, download_items):
        tgz_item = download_items[0]

        # Unpack the package.
        check_call(["tar", "xzf", tgz_item.filename])
        old_directory = "%s-%s.1-linux-x86_64" % (self.package, self.version)

        # Create a version-less directory name to tar up.
        new_directory = "cyren-%s" % self.package
        check_call(["mv", old_directory, new_directory])

        # Return a list of files to tar up.
        return [new_directory]


class GenericPackageFileCreator(PackageFileCreator):
    """
    Generic Package Creator.  Generates a .tar.gz file containing the downloaded files.
    """

    def __init__(self, package,  *args, **kwargs):
        super(GenericPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = package['name']
        self.sample_version = package['version']
        self.files = package['files']

    def _get_download_items(self):
        items = []


        for file in self.files:
            url  = file['url'].format(version = self.sample_version)

            file['url'] = url
            file['filename'] = os.path.basename(url)

            for field in self.ItemFields:
                if field not in file:
                    file[field] = None
                else:
                    file[field] = file[field].format(version = self.sample_version)

            values = [file[key] for key in self.ItemFields]
            item = self.DownloadItem(*values)
            items.append(item)

        return items


class JDKPackageFileCreator(PackageFileCreator):
    """
    JDK Package Creator.  Generates a .tar.gz file containing the Oracle JDK files.
    """

    def __init__(self, *args, **kwargs):
        super(JDKPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "jdk"
        self.sample_version = "1.7.0_71-b14"

    def _set_version(self, version):
        """
        Parse an Oracle JDK version string like 1.7.0_71-b14 or 1.8.0_312-b07.
        """

        m = re.match(r'^1\.(\d+)\.0_(\d+)-b(\d+)$', version)
        assert m is not None, "Invalid JDK version: %s" % version

        self.version = version
        self.major = int(m.group(1))
        self.minor = int(m.group(2))
        self.build = int(m.group(3))

    def _get_download_items(self):
        """
        Generate both the JDK and JCE URLs for download.
        """
        jdk_url = "http://download.oracle.com/otn-pub/java/jdk/"
        jdk_url += "%du%d-b%d/jdk-%du%d-linux-x64.tar.gz" % (
                self.major,
                self.minor,
                self.build,
                self.major,
                self.minor)

        jdk_filename = os.path.basename(jdk_url)

        jce_url = "http://download.oracle.com/otn-pub/java/jce/%d/" % (self.major)
        if self.major == 7:
            jce_url += "UnlimitedJCEPolicyJDK7.zip"
        elif self.major == 8:
            jce_url += "jce_policy-8.zip"
        else:
            raise Exception("Invalid JCE version: %d" % self.major)

        jce_filename = os.path.basename(jce_url)

        wget_options=[
            "--no-check-certificate",
            "--no-cookies",
            "--header", "Cookie: oraclelicense=accept-securebackup-cookie",
        ]

        items = []
        items.append(self.DownloadItem(jdk_filename, jdk_url, wget_options))
        items.append(self.DownloadItem(jce_filename, jce_url, wget_options))
        return items

    def _prepare_files_for_packing(self, download_items):
        jdk_tgz_item = download_items[0]
        jce_zip_item = download_items[1]

        # Unpack the JDK package.
        check_call(["tar", "xzf", jdk_tgz_item.filename])
        old_directory = "jdk1.%s.0_%s" % (self.major, self.minor)

        # Create a version-less directory name to tar up.
        new_directory = "java-%s-oracle" % self.major
        check_call(["mv", old_directory, new_directory])

        # Unzip the JCE package.
        check_call(["unzip", jce_zip_item.filename])

        # Extracted JCE path differs between JDK7 and JDK8
        jce_path = ""
        if self.major == 8:
            jce_path = "JDK%d" % self.major

        # Add the unlimited strength files to the directory.
        jce_directory = "UnlimitedJCEPolicy" + jce_path
        jce_export_policy_path = jce_directory + "/US_export_policy.jar"
        jce_local_policy_path = jce_directory + "/local_policy.jar"
        export_policy_path = new_directory + "/jre/lib/security/US_export_policy.jar"
        local_policy_path = new_directory + "/jre/lib/security/local_policy.jar"

        check_call(["mv", jce_export_policy_path, export_policy_path])
        check_call(["mv", jce_local_policy_path, local_policy_path])

        # Return a list of files to tar up.
        return [new_directory]


class LibSpf2PackageFileCreator(PackageFileCreator):
    """
    libspf2 Package Creator.  Generates a .tar.gz file containing the required rpm package.
    """

    def __init__(self, *args, **kwargs):
        super(LibSpf2PackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "libspf2"
        self.sample_version = "1.2.10-9"

    def _get_download_items(self):
        url = "http://www.city-fan.org/ftp/contrib/libraries//%s-%s.el6.x86_64.rpm" % (self.package, self.version)

        filename = os.path.basename(url)

        return [self.DownloadItem(filename, url, [])]


class MongodbMmsPackageFileCreator(AbstractBaseDirectoryPackageFileCreator):
    """
    Mongodb Mms Package Creator.  Generates a .tar.gz file containing the required RPM files for
    mongo Ops Manager installation.
    """

    def __init__(self, *args, **kwargs):
        super(MongodbMmsPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "mongodb-mms"
        self.sample_version = "3.4.7.479-1"

    def _set_version(self, version):
        self.version = version

        m = re.match("^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})-(\d{1,3})$", self.version)
        if m:
            self.version_component_count = m.groups
            self.major = int(m.group(1))
            self.minor = int(m.group(2))
            self.micro = int(m.group(3))
            self.nano = int(m.group(4))
            self.pico = int(m.group(5))

            # create some common aliases
            self.patch = self.micro
            self.build = self.nano
            self.release = self.pico

            # this will push up a version string into 1002003004005, this is useful for
            # detecting newer versions or comparing versions when version string can be
            # a little unstable (ie distro versions, build versions, 3rd party versions on
            # top of upstream versions)

            self.numeric_version = 0

            for g in m.groups() :
                self.numeric_version *= 1000
                self.numeric_version += int(g)

            return

        raise ValueError("cannot parse version: '%s'" % version)

    def _get_download_items(self):
        items = []

        filename = "%s.x86_64.rpm" % (self.get_package_file_basename())

        url = "https://downloads.mongodb.com/on-prem-mms/rpm/%s" % (filename)

        items.append(self.DownloadItem(filename, url, []))

        return items

class MongodbPackageFileCreator(PackageFileCreator):
    """
    Mongodb Package Creator.  Generates a .tar.gz file containing the required RPM files.
    """

    RPM_NAMES = [
        "mongodb-org",
        "mongodb-org-mongos",
        "mongodb-org-server",
        "mongodb-org-shell",
        "mongodb-org-tools",
    ]

    def __init__(self, *args, **kwargs):
        super(MongodbPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "mongodb"
        self.sample_version = "3.2.4"

    def _get_download_items(self):
        items = []

        for rpm_name in self.RPM_NAMES:
            # mongodb.org has separate directories for RedHat and Amazon Linux.
            # Its amazon directory has a single subdirectory, 2013.03, but this
            # directory should be valid for any release of Amazon Linux.
            url = "https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/"
            url += "%d.%d/x86_64/RPMS/%s-%s-1.amzn1.x86_64.rpm" % (
                    self.major, self.minor, rpm_name, self.version)

            filename = rpm_name + ".rpm"

            items.append(self.DownloadItem(filename, url, []))

        return items


class NginxPushStreamModulePackageFileCreator(PackageFileCreator):
    """
    Nginx + Lua + Push Stream Module Package Creator.  Generates a .tar.gz file containing OpenResty build
    and push-stream-module. OpenResty build is nginx + lua and other modules.
    """

    OPENRESTY_VER = "1.13.6.1"
    PSM_VER = "0.5.2"

    OPENRESTY_PUBKEY = """-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: SKS 1.1.5
Comment: Hostname: pgp.mit.edu

mQENBFEhd7QBCACmZfgn3demo4su81XIAVUVGX7X9Ch6t2vWjMZHF7tVkK82xTba4ya6So1b
ptYm7o3OWFIHiln5sYSZCLn/ArXAMCWoqgN5vJDZn+yYMxT7AB11wrfTcnbkg5HgPD7SM8f2
q/pN7B8W7gT90QCqYSalr2uLvEd5yyciQk+3LysXeghuT9zYYNxB0yjKvLVGjnNIcMKeE/J2
+zzprZqsBTzmgi5eoC7iLIaO2SRWza+/Q2/NYe5x9yGr+ySycxtYrYw6huHkYIxg4ryfmj2c
5WCYl926RIJ4vCFAlaBgH2tWHQWLmUL6FU42GLdDUPunrIKmBXBu/vBE6uhpIOkZjXRZABEB
AAG0KllpY2h1biBaaGFuZyAoYWdlbnR6aCkgPGFnZW50emhAZ21haWwuY29tPokBOAQTAQIA
IgUCUSF3tAIbAwYLCQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQtVDgnqDpgGYBDQf5Abc9
p8R77VlABsCWDyiLDQFR9yIqZj3wmjj4GZYtC0PLj3rT6TzbAMExIdEsXD83+a4drLc/BVIF
RON6BvQOh6zihQAdHCUoBbA+WhWFUW5OoiF54a5hosb+HV/jkuBF9xsRJ6v0vje3jdZEFLNB
OkxnDiqMTGO4tSFerR+bkicF+hM7VvjFuaIj2qi7Z7WABVsMfVJF3K6T9AxHY09mpSf+cGGt
5J2O22DwL16R9zQO8h8jKsNenxdRHWWUgBNYtM19R2a6Yy1Xvma2c0fhtKOCsYGeGXFrw2Px
+4DfCfMJMhJXyv0bAqhAkFnyBWv3sdtA+b7thaxjDYXb9OmltLkBDQRRIXe0AQgA05JGEyzZ
tgyhZk7s3dl5GIjLqaOjdrk+pbD4Qhg7Id1yBDs93Oe4NklRgLB/uwXReXWTm7IyQwyLWI1g
/elQVk1cCivmHoD+5IzNeC/aRdfWJUWYOC4AVWiHqByPXREGC97BxPmHR6xgug6ze4kGqLKs
Tikax21/w3U6Gs57Z1Rsgi8xPvcvKOR2OHRoL2+5C5W23AFuOvnZxlBXO0aZw7FUJ4jlWOLt
V2IldyCFTKouHmJg+TsXfnBqfQzfAJ/MjHaqzjrpAo5uxaUdFD1/OooHy7RCF/1wRw6C9raL
zGkGLxKB+3hYjrBPOLyGpqjohNNG/9Dmh0HBPMCHDbnmyQARAQABiQEfBBgBAgAJBQJRIXe0
AhsMAAoJELVQ4J6g6YBm0FsH/1NWqmSgx9fLdxdS/uVNN5gyiwockFjL83Jvd8a6kyCOjxDJ
hCV4A8g3Klz3eIohB5+4dMwHdQz0dMbZFNXQrySNxWWuScO0sP/+lDXc+px9UpLFpx4bM1uh
SGOADjilLvWMySV9AFPc4eHqbHp9BwaWO8XArRgH4eoKSjI89vzIKNHdXunv9e9NpIIyEAtl
XZ5c9YGROCuw4oYqQizdeHI46si+7SiXqstpNu1Cp7LVPOEQ2zEBTrz4sozW4jr6yRw7Y/8d
ir7EOc0v78K+9BbsvUJOK2EcEEp4Zya9YPWhVSQ4h5IECKyEwj4D5D4PZxvVyH2ghjMmT7z6
AB2dkm4=
=6OnT
-----END PGP PUBLIC KEY BLOCK-----"""

    def __init__(self, *args, **kwargs):
        super(NginxPushStreamModulePackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "nginx-push-stream-module"
        self.sample_version = "1.0.0"

    def _get_download_items(self):
        OPENRESTY_URL = "https://openresty.org/download/openresty-%s.tar.gz" % self.OPENRESTY_VER
        OPENRESTY_SIG_URL = "https://openresty.org/download/openresty-%s.tar.gz.asc" % self.OPENRESTY_VER
        PSM_URL = "https://github.com/wandenberg/nginx-push-stream-module/archive/%s.tar.gz" % self.PSM_VER
        PCRE_URL = "https://sourceforge.net/projects/pcre/files/pcre/8.39/pcre-8.39.tar.gz"

        items = []
        items.append(self.DownloadItem("openresty-%s.tar.gz" % self.OPENRESTY_VER, OPENRESTY_URL, []))
        items.append(self.DownloadItem("openresty-%s.tar.gz.asc" % self.OPENRESTY_VER, OPENRESTY_SIG_URL, []))
        items.append(self.DownloadItem("nginx-push-stream-module-%s.tar.gz" % self.PSM_VER, PSM_URL, []))
        items.append(self.DownloadItem("pcre-8.39.tar.gz", PCRE_URL, []))

        return items

    def _prepare_files_for_packing(self, download_items):

        openresty, openresty_sig, psm, pcre = download_items

        file("pub.txt", "w").write(self.OPENRESTY_PUBKEY)

        # Verify openresty
        check_call(["gpg", "--import", "pub.txt"])
        check_call(["gpg", "--verify", openresty_sig.filename, openresty.filename])

        # Verify pcre
        PCRE_SHA1 = "b3aec1f643d9701841e2f9d57ac121a7ff448fc8"
        if check_output(["sha1sum", pcre.filename]).strip().split()[0] <> PCRE_SHA1:
            raise Exception("%s: Invalid sha1" % pcre.filename)

        # check_call(["sudo", "yum", "groupinstall", "-y", "Development Tools"])
        # check_call(["sudo", "yum", "install", "-y", "pcre-devel"])
        # check_call(["sudo", "yum", "install", "-y", "openssl-devel"])

        cwd = os.getcwd()
        os.mkdir("openresty.push")

        check_call(["tar", "-xf", "../" + openresty.filename], cwd="openresty.push")
        check_call(["tar", "-xf", "../" + psm.filename], cwd="openresty.push")
        check_call(["tar", "-xf", "../" + pcre.filename], cwd="openresty.push")

        check_call(["mv", "openresty-" + self.OPENRESTY_VER, "openresty"], cwd="openresty.push")

        # Patch ping message from push stream module
        psm_path = "%s/openresty.push/nginx-push-stream-module-%s" % (cwd, self.PSM_VER)
        check_call([
            "sed", "-i", "s/: \-1/:/", "%s/include/ngx_http_push_stream_module_utils.h" % psm_path
        ])

        check_call([
            cwd+"/openresty.push/openresty/configure",
            "--add-module=../nginx-push-stream-module-" + self.PSM_VER,
            "--with-pcre=../pcre-8.39",
            "--user=nginx",
            "--group=nginx"]
            , cwd="openresty.push/openresty")
        check_call(["make"], cwd="openresty.push/openresty")

        return ["openresty.push"]


class PackerPackageFileCreator(PackageFileCreator):
    """
    Packer Package Creator.  Generates a .tar.gz file containing the required executable.
    """

    def __init__(self, *args, **kwargs):
        super(PackerPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "packer"
        self.sample_version = "0.10.1"

    def _get_download_items(self):
        url = "https://releases.hashicorp.com/packer/%s/packer_%s_linux_amd64.zip" % (self.version, self.version)

        filename = os.path.basename(url)

        return [self.DownloadItem(filename, url, [])]

    def _prepare_files_for_packing(self, download_items):
        zip_item = download_items[0]

        # Unpack the package.
        check_call(["unzip", zip_item.filename])

        # Return a list of files to tar up.
        return ["packer"]


class SavdiPackageFileCreator(PackageFileCreator):
    """
    SAV-DI Package Creator.  Generates a .tar.gz file containing the required files.
    Sophos Antivirus Dynamic Interface (SAV-DI) is a socket based scanner that acts as a wrapper to SAVI and runs as a daemon or service.
    """

    def __init__(self, *args, **kwargs):
        super(SavdiPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "savdi"
        self.sample_version = "2.3"

    def _set_version(self, version):
        """
        Parse a SAV-DI version string like 2.3.
        """

        version_components = version.split(".")
        assert len(version_components) == 2

        self.version = version
        self.major = int(version_components[0])
        self.minor = int(version_components[1])

    def _get_download_items(self):

        url = "https://downloads.sophos.com/sophos/products/full/"
        url += "%s-linux-64bit.tar" % (self.package)

        filename = os.path.basename(url)

        wget_options = [
            "--user=%s" % self.username,
            "--password=%s" % self.password,
            ]

        return [self.DownloadItem(filename, url, wget_options)]

    def _prepare_files_for_packing(self, download_items):
        tz_item = download_items[0]

        # Unpack the package.
        check_call(["tar", "xf", tz_item.filename])
        directory = "savdi-install"

        # Return a list of files to tar up.
        return [directory]


class SaviPackageFileCreator(PackageFileCreator):
    """
    SAVI Package Creator.  Generates a .tar.gz file containing the required files.
    Sophos Antivirus Interface (SAVI) is a C/C++ interface to the Sophos Antivirus engine dlls or shared library.
    """

    def __init__(self, *args, **kwargs):
        super(SaviPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "savi"
        self.sample_version = "2.3"

    def create_package_file_from_download(self, version, username, password):
        """
        Download the specified version of a package into the current directory.
        Take those package files and create a .tar.gz file from them.
        Return the name of the created .tar.gz file.
        """

        self.set_version(version)
        self.set_username(username)
        self.set_password(password)

        download_items = self.get_download_items()

        for item in download_items:
            if item.filename == "ide":
                ide_version = get_data_version("vdl.zip")
                filename = 'ide_%s.zip' % ide_version
                url = "%sdata/%s" % (item.url, filename)
                item = item._replace(filename=filename, url=url)
                download_items[2] = item
            wget(item.url, item.filename, item.wget_options)

        basename = self.get_package_file_basename()

        prepared_files = self.prepare_files_for_packing(download_items)

        return create_tar_gz(basename, prepared_files)

    def _set_version(self, version):
        """
        Parse a SAVI version string like 2.3.
        """

        version_components = version.split(".")
        assert len(version_components) == 2

        self.version = version
        self.major = int(version_components[0])
        self.minor = int(version_components[1])

    def _get_download_items(self):
        items = []

        base_url = "https://downloads.sophos.com/sophos/products/full/OEM/SAVi/"
        savi_url = "%scurrent/unix/linux.amd64.glibc.%s.tar" % (base_url, self.version)
        vdl_url = "%sdata/vdl.zip" % base_url

        savi_filename = os.path.basename(savi_url)
        vdl_filename = os.path.basename(vdl_url)

        wget_options = [
            '--user=%s' % self.username,
            '--password=%s' % self.password,
            '--user-agent="SophosSAVDownload/1.00 wget/1.0 (u=\"%s\")"' % self.username,
            ]

        items.append(self.DownloadItem(savi_filename, savi_url, wget_options))
        items.append(self.DownloadItem(vdl_filename, vdl_url, wget_options))
        items.append(self.DownloadItem("ide", base_url, wget_options))
        return items

    def _prepare_files_for_packing(self, download_items):
        savi_item = download_items[0]
        vdl_item = download_items[1]
        ide_item = download_items[2]

        # Unpack the package.
        check_call(["tar", "xf", savi_item.filename])
        directory = "sav-install"

        # Return a list of files to tar up.
        return [directory, vdl_item.filename, ide_item.filename]


class SophosFluentdPackageFileCreator(PackageFileCreator):
    """
    Creates docker container for fluentd.
    """
    def __init__(self, script_path,  *args, **kwargs):
        super(SophosFluentdPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "sophos-fluentd"
        self.sample_version = "0.12.35"
        self.image_name = "sophos/%s" % self.package
        self.source_dockerfile = os.path.realpath(
            os.path.join(
                script_path,
                '..',
                'docker',
                self.package,
                'Dockerfile'
            )
        )

    def _get_download_items(self):
        return []

    def _prepare_files_for_packing(self, ignored_download_items):

        dockerfile = os.path.realpath('Dockerfile')

        shutil.copy(self.source_dockerfile, dockerfile)

        check_call([
            'sed',
            # -i'.bak' will allow this to build on Mac
            '-i''.bak''',
            's:@FLUENTD_VERSION@:%s:g' % self.version,
            dockerfile
        ])

        image_tag = "%s:v%s" %(self.image_name, self.version)

        print(
            "Building %s with tag <%s>" % (
                dockerfile,
                image_tag
            )
        )

        cli = docker.APIClient()

        with open(dockerfile) as f:
            for line in cli.build(
                fileobj = f,
                tag = image_tag,
                pull = True
            ):
                print(line.strip())

        versioned_name = self.get_package_file_basename()

        os.makedirs(versioned_name)

        image_filename = os.path.join(
            versioned_name,
            "%s-docker.tar" % versioned_name
        )

        image = cli.get_image(image_tag)
        with open(image_filename, 'w') as f:
            f.write(image.data)

        with open(
            os.path.join(
                versioned_name,
                "%s-inspect.json" % versioned_name
            ),
            'w'
        ) as f:
            json.dump(
                obj = cli.inspect_image(image_tag),
                fp = f,
                indent = 4
            )

        # Return a list of files to tar up.
        return [versioned_name]


class TDAgentPackageFileCreator(PackageFileCreator):
    """
    TD-Agent (Fluentd) Package Creator.  Generates a .tar.gz file containing the required rpm package.
    """

    def __init__(self, *args, **kwargs):
        super(TDAgentPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "td-agent"
        self.sample_version = "2.3.5-0"

    def _get_download_items(self):
        url = "http://packages.treasuredata.com.s3.amazonaws.com/2/redhat/6/x86_64/%s-%s.el6.x86_64.rpm" % (self.package, self.version)

        filename = os.path.basename(url)

        return [self.DownloadItem(filename, url, [])]


class TerraformPackageFileCreator(PackageFileCreator):
    """
    Terraform Package Creator.  Generates a .tar.gz file containing the required TF executable.
    """

    def __init__(self, *args, **kwargs):
        super(TerraformPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "terraform"
        self.sample_version = "0.11.7"

    def _get_download_items(self):
        url = "https://nexus.sophos-tools.com/repository/build-assets/%s_%s" % (self.package, self.version)

        package_directory = self.get_package_file_basename()

        os.makedirs(package_directory)

        filename = os.path.join(package_directory, self.package)

        return [self.DownloadItem(filename, url, [])]

    def _prepare_files_for_packing(self, ignored_download_items):

        package_directory = self.get_package_file_basename()

        filename = os.path.join(package_directory, self.package)
        st = os.stat(filename)

        os.chmod(filename, st.st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

        return [package_directory]

class TomcatPackageFileCreator(PackageFileCreator):
    """
    Tomcat Package Creator.  Generates a .tar.gz file containing the required files.
    """

    def __init__(self, *args, **kwargs):
        super(TomcatPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "tomcat"
        self.sample_version = "8.0.32"

    def _get_download_items(self):
        tgz_url = "http://www-us.apache.org/dist/tomcat/"
        tgz_url += "tomcat-%s/v%s/bin/apache-tomcat-%s.tar.gz" % (
                self.major, self.version, self.version)
        tgz_filename = os.path.basename(tgz_url)

        md5_url = tgz_url + ".md5"
        md5_filename = tgz_filename + ".md5"

        items = []
        items.append(self.DownloadItem(tgz_filename, tgz_url, []))
        items.append(self.DownloadItem(md5_filename, md5_url, []))
        return items

    def _get_package_file_basename(self):
        # Override for backwards compatibility -- the existing tomcat packages
        # have no hyphen between package and version.
        return "%s%s" % (self.package, self.version)

    def _prepare_files_for_packing(self, download_items):
        tgz_item = None
        md5_item = None

        for item in download_items:
            if item.url.endswith(".tar.gz"):
                tgz_item = item
            elif item.url.endswith(".tar.gz.md5"):
                md5_item = item
            else:
                die("unexpected %s download item url: %s" % (self.package, item.url))

        if tgz_item is None:
            die("missing %s .tar.gz download item" % self.package)

        if md5_item is None:
            die("missing %s .tar.gz.md5 download item" % self.package)

        # Check the integrity of the download.
        check_md5(tgz_item.filename, md5_item.filename)

        # Unpack the package.
        check_call(["tar", "xzf", tgz_item.filename])
        old_directory = "apache-tomcat-" + self.version

        # Create a version-less directory name to tar up.
        new_directory = "tomcat"
        check_call(["mv", old_directory, new_directory])

        # Clear out the default webapps stuff.
        check_call(["sh", "-c", "rm -rf %s/webapps/*" % new_directory])

        # Clear out Windows .bat files.
        check_call(["find", new_directory, "-name", "*.bat", "-exec", "rm", "{}", ";"])

        # Return a list of files to tar up.
        return [new_directory]


class WildflyPackageFileCreator(PackageFileCreator):
    """
    Wildfly Package Creator.  Generates a .tar.gz file containing the required files.
    """

    def __init__(self, *args, **kwargs):
        super(WildflyPackageFileCreator, self).__init__(*args, **kwargs)
        self.package = "wildfly"
        self.sample_version = "10.0.0.Final"

    def _set_version(self, version):
        """
        Parser an Wildfly version string like 10.0.0.Final.
        """

        m = re.match(r'^(\d+).(\d+).(\d+).Final$', version)
        assert m is not None, "Invalid Wildfly version: %s" % version

        self.version = version
        self.major = int(m.group(1))
        self.minor = int(m.group(2))
        self.build = int(m.group(3))

    def _get_download_items(self):
        tgz_url = "http://download.jboss.org/wildfly/"
        tgz_url += "%s/wildfly-%s.tar.gz" % (self.version, self.version)
        tgz_filename = os.path.basename(tgz_url)

        items = []
        items.append(self.DownloadItem(tgz_filename, tgz_url, []))
        return items

    def _get_package_file_basename(self):
        # Override for backwards compatibility -- the existing wildfly packages
        # have no hyphen between package and version.
        return "%s%s" % (self.package, self.version)

    def _prepare_files_for_packing(self, download_items):
        tgz_item = None
        md5_item = None

        for item in download_items:
            if item.url.endswith(".tar.gz"):
                tgz_item = item
            elif item.url.endswith(".tar.gz.md5"):
                md5_item = item
            else:
                die("unexpected %s download item url: %s" % (self.package, item.url))

        if tgz_item is None:
            die("missing %s .tar.gz download item" % self.package)

        # Unpack the package.
        check_call(["tar", "xzf", tgz_item.filename])
        old_directory = "wildfly-" + self.version

        # Create a version-less directory name to tar up.
        new_directory = "wildfly"
        check_call(["mv", old_directory, new_directory])

        # Clear out Windows .bat files.
        check_call(["find", new_directory, "-name", "*.bat", "-exec", "rm", "{}", ";"])

        # Return a list of files to tar up.
        return [new_directory]


def _main():
    script_path = os.path.dirname(os.path.realpath(__file__))

    PACKAGE_FILE_CREATORS = [
        ChefPackageFileCreator(),
        CyrenPackageFileCreator(),
        JDKPackageFileCreator(),
        LibSpf2PackageFileCreator(),
        MongodbMmsPackageFileCreator(),
        MongodbPackageFileCreator(),
        NginxPushStreamModulePackageFileCreator(),
        PackerPackageFileCreator(),
        SavdiPackageFileCreator(),
        SaviPackageFileCreator(),
        SophosFluentdPackageFileCreator(script_path = script_path),
        TDAgentPackageFileCreator(),
        TerraformPackageFileCreator(),
        TomcatPackageFileCreator(),
        WildflyPackageFileCreator()
    ]

    options, package, version, username, password, creator = parse_command_line(PACKAGE_FILE_CREATORS)

    package_file = None

    tmpdir = options.tmpdir
    if tmpdir is None:
        tmpdir = tempfile.mkdtemp()

    try:
        cwd = os.getcwd()
        try:
            os.chdir(tmpdir)
            package_file = creator.create_package_file_from_download(version, username, password)
            check_call(["mv", package_file, cwd])
        finally:
            os.chdir(cwd)
    finally:
        if options.keep or options.tmpdir is not None:
            info("keeping temporary directory %s" % tmpdir)
        else:
            check_call(["rm", "-rf", tmpdir])

    if package_file is None:
        die("failed to create package file for %s version %s" % (package, version))

    if options.summary is not None:
        with open(options.summary, "w") as fp:
            print("Package=%s" % package, file=fp)
            print("Version=%s" % version, file=fp)
            print("PackageFile=%s" % package_file, file=fp)

    info("created package file %s" % package_file)


if __name__ == "__main__":
    _main()
