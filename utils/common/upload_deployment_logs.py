#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Upload log files to S3.
"""

import datetime
import optparse
import os
import pytz
import subprocess
import sys
import time

import sophos_common


DEFAULT_LOG_SOURCES = """
/var/chef/chef-repo/cookbooks.tar.gz
/var/chef/chef-repo/nodes
/var/log
/var/sophos

/opt/sophos

/data/log

/etc/ami-lineage.log
/etc/hosts
/etc/image-id
/etc/init.d
/etc/issue
/etc/motd
/etc/os-release
/etc/resolv.conf
/etc/system-release

/proc/cpuinfo
/proc/diskstats
/proc/meminfo
/proc/mounts
/proc/partitions
/proc/stat
/proc/version
/proc/vmstat

/usr/local/etc/sophos
""".split()


DEFAULT_LOG_EXCLUSIONS = """
/opt/sophos/packages/*
/opt/sophos/rpms/*
""".split()


DEFAULT_LOG_COMMANDS = {
    "df.out":           "/bin/df -hT",
    "ifconfig.out":     "/sbin/ifconfig -a",
    "iptables.out":     "/sbin/iptables -S",
    "lsof.out":         "/usr/sbin/lsof -P",
    "mount.out":        "/bin/mount -l",
    "netstat-r.out":    "/bin/netstat -rn",
    "top.out":          "/usr/bin/top -b -n 1",
    "journalctl.out":   "/bin/journalctl -xe",
    "uname.out":        "/bin/uname -a",
}


def parse_command_line():
    parser = optparse.OptionParser(
            usage="%prog [options] <deployment-name> [<extra_log_sources> ...]",
            epilog="Note: the --account and --branch options are REQUIRED.")

    parser.add_option(
            "-a", "--account", default=None,
            help="Specify deployment account, e.g. dev, qa, prod ...")

    parser.add_option(
            "-b", "--branch", default=None,
            help="Specify deployment branch, e.g. develop, feature/CPLAT-1234 ...")

    parser.add_option(
            "-c", "--command", metavar="FILENAME=COMMAND",
            action="append", dest="commands", default=[],
            help="Specify additional command to log, e.g. -c 'df.out=df -hT'")

    parser.add_option(
            "-n", "--noupload", action="store_true", default=False,
            help="Disable upload to S3")

    options, args = parser.parse_args()

    if options.account is None:
        parser.error("missing required --account option")

    if options.branch is None:
        parser.error("missing required --branch option")

    for command in options.commands:
        if "=" not in command:
            parser.error("parse error for command option: %r" % command)

    if len(args) < 1:
        parser.error("missing required <deployment-name> argument")

    deployment_name = args[0]

    extra_log_sources = args[1:]

    return options, deployment_name, extra_log_sources


def main():
    options, name, extra_sources = parse_command_line()

    region = sophos_common.aws_region()

    bucket = "cloud-%s-logs" % options.account

    dt = datetime.datetime.fromtimestamp(time.time(), pytz.utc)

    keydir = "/".join([
        dt.strftime("%Y"),
        dt.strftime("%m"),
        dt.strftime("%d-%a"),
        "deployments",
        region,
        name])

    instance_id = sophos_common.aws_instance_id()

    # Including datetime at the beginning of each filename makes it easy to
    # find the file for the most recent deployment in the AWS S3 console.
    zipname = "deploy-%s-%s-%s" % (
            dt.strftime("%Y%m%d.%H%M%S"),
            name,
            instance_id)

    logdir = "/tmp/" + zipname

    # Populate logdir with content we want to save.
    os.chdir(os.path.dirname(logdir))
    subprocess.call(["/bin/rm", "-rf", zipname])
    subprocess.call(["/bin/rm", "-rf", zipname + ".zip"])

    # Create symbolic links to existing content.
    sources = DEFAULT_LOG_SOURCES + extra_sources
    for source in sources:
        if os.path.isdir(source) or os.path.isfile(source):
            stripped_source = source.strip("/")
            dirname = os.path.dirname(stripped_source)
            subprocess.check_call(["/bin/mkdir", "-p", logdir + "/" + dirname])
            subprocess.check_call(["/bin/ln", "-s", source, logdir + "/" + stripped_source])

    # Save output from commands we want to log.
    items = DEFAULT_LOG_COMMANDS.items()
    for custom_command in options.commands:
        filename, command = custom_command.split("=", 1)
        items.append((filename, command))
    for filename, command in items:
        with open(logdir + "/" + filename, "w") as fp:
            try:
                print >> fp, subprocess.check_output(command.split())
            except subprocess.CalledProcessError as e:
                print >> fp, str(e)

    # Flush OS buffers so zip command gets most recent data.
    # Ignore return code to avoid bypassing the zip and upload steps if sync fails.
    retcode = subprocess.call(["/bin/sync"])
    if retcode != 0:
        sophos_common.msg("sync command exited with status %r, continuing anyway..." % retcode)

    # Generate exclusion arguments to pass to zip command.
    # If we use the -x option we must specify at least one file,
    # so we always pass /dev/null to satisfy that requirement.
    # The zip command processes shell wildcard characters
    # for us, so we don't have to add any code to do that on
    # our own.
    exclusion_args = ["-x", "/dev/null"]
    for exclusion_path in DEFAULT_LOG_EXCLUSIONS:
        exclusion_args.append(zipname.rstrip("/") + "/" + exclusion_path.lstrip("/"))

    # Create the zip file.
    subprocess.check_call(["/usr/bin/zip", "-rq", logdir + ".zip", zipname] + exclusion_args)
    print "Created", logdir + ".zip"

    # Are we done yet?
    if options.noupload:
        return

    # Upload the zip file.
    # Retry a couple times if the first upload attempts fail.
    command = ["/usr/bin/aws", "s3", "cp", logdir + ".zip", "s3://%s/%s/%s.zip" % (bucket, keydir, zipname)]
    sophos_common.msg("Running: %s" % " ".join(command))
    for attempt in range(3):
        retcode = subprocess.call(command)
        if retcode == 0:
            break
        time.sleep(5)


if __name__ == "__main__":
    main()
