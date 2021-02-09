#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
MongoDB utilities for Sophos Central applications.
"""

import argparse
import collections
import copy
import datetime
import json
import logging
import os
import pymongo
import signal
import subprocess
import sys
import yaml

import sophos.aws
import sophos.common

MONGOD_CONF_PATH = "/etc/mongod.conf"

MONGOS_CONF_PATH_FOR_MONGOD_INST = "/etc/mongos.conf"

MONGO_CLIENT_CONF_PATH = "/etc/mongos/config/mongos.conf"

MONGOS_CLUSTERED_CONF_PATH = "/etc/mongos/config/mongos.conf"

MONGOD_FTDC_DIRECTORY = "/mongodata/db/diagnostic.data"

MONGOS_FTDC_DIRECTORY = "/var/log/mongos/mongos.diagnostic.data"

MONGO_LOG_DIRECTORY = "/data/log/mongodb"

MONGOS_LOG_DIRECTORY = "/var/log/mongos"

# Return values for get_mongod_health when replica set member state cannot
# be determined.
MONGO_HEALTH_NOT_RUNNING = "NotRunning"
MONGO_HEALTH_MAY_HAVE_CRASHED = "MayHaveCrashed"
MONGO_HEALTH_AUTH_FAILED = "AuthFailed"
MONGOS_HEALTH_NO_SHARDS_FOUND="NoShardsFound"

# DO NOT CHANGE THIS!  Java code in sophos-cloud depends on this value!  Specifically, if this is changed, then
# com.sophos.cloud.data.mongo.MongoClientFactory.TAG_VALUE_LAST_HEALTH_HEALTHY would also have to be changed.
MONGOS_HEALTH_HEALTHY="Healthy(%d)"

# Replica set member states.
# Note: these states are NOT all available via constants in pymongo.
# Reference: http://docs.mongodb.org/manual/reference/replica-states/
MONGO_MEMBER_STATES = {
    "0":  "STARTUP",
    "1":  "PRIMARY",
    "2":  "SECONDARY",
    "3":  "RECOVERING",
    "4":  "FATAL",
    "5":  "STARTUP2",
    "6":  "UNKNOWN",
    "7":  "ARBITER",
    "8":  "DOWN",
    "9":  "ROLLBACK",
    "10": "REMOVED",
}

# Healthy replica set member states.
# Reference: http://docs.mongodb.org/manual/reference/replica-states/
MONGO_HEALTHY_MEMBER_STATES = set([
    "STARTUP",
    "PRIMARY",
    "SECONDARY",
    "RECOVERING",
    "STARTUP2",
    "ARBITER",
])


def get_mongo_connection_args(*services, **kwargs):
    """
    Return list of MongoDB connection args applicable to the current environment.
    The result is suitable for passing to argparse.ArgumentParser.parse_args(),
    so long as support for --port, --username, and --password options has been added.
    This minimizes the Sophos-dependent code needed for custom MongoDB utilities.

    Options:

    The --port option is included if it can be extracted from the service configuration file.
    The `services` parameter controls which services are supported, and which takes precedence.

    The --username and --password options will be included if they can be determined.

    Addition of these options will be suppressed if they are already present in argv.

    Example:

        parser = argparse.ArgumentParser(...)
        parser.add_argument("--port", ...)
        parser.add_argument("--username", ...)
        parser.add_argument("--password", ...)
        ...
        args = parser.parse_args(get_mongo_connection_args("mongod", "mongos") + sys.argv[1:])
        ...

    Even better:

        parser = sophos.mongo.MongoArgumentParser("mongod", "mongos", doc=__doc__)
        ...
        args = parser.parse_args()
        ...
    """

    argv = kwargs.get("argv", sys.argv)

    args = []

    mongo_conf_paths = []

    replset_conf_paths = ["/mongodata/config/replica-set.json"]

    for service in services:
        mongo_conf_paths.append("/etc/%s.conf" % service)
        mongo_conf_paths.append("/etc/%s/config/%s.conf" % (service, service))
        replset_conf_paths.append("/etc/%s/config/replica-set.json" % service)

    for mongo_conf_path in mongo_conf_paths:
        try:
            with open(mongo_conf_path) as f:
                mongo_conf = yaml.safe_load(f)
                port = mongo_conf["net"]["port"]
                if not argv or "--port" not in argv:
                    args.extend(["--port", str(port)])
                break
        except IOError, KeyError:
            pass

    for replset_conf_path in replset_conf_paths:
        try:
            with open(replset_conf_path) as f:
                replset_conf = json.load(f)
                username = replset_conf["admin_username"]
                password = replset_conf["admin_password"]
                if not argv or "--username" not in argv:
                    args.extend(["--username", username])
                if not argv or "--password" not in argv:
                    args.extend(["--password", password])
                if not argv or "--authenticationDatabase" not in argv:
                    args.extend(["--authenticationDatabase", "admin"])
                break
        except IOError, KeyError:
            pass

    return args


class MongoArgumentParser(argparse.ArgumentParser):
    """Subclass of argparse.ArgumentParser that automatically adds connection options.
    Options added include:
    --host to specify the host to connect to
    --port to specify the port to connect to
    --username to specify the username to authenticate with
    --password to specify the password to authenticate with
    """

    def __init__(self, *services, **kwargs):
        self._services = services

        doc = kwargs.get("doc")

        if doc is not None:
            # Add newline before the split to ensure we get two strings, even if doc is empty.
            description, epilog = (doc.strip() + "\n").split("\n", 1)
            kwargs["description"] = description
            kwargs["epilog"] = epilog

        if "doc" in kwargs:
            del kwargs["doc"]

        if "formatter_class" not in kwargs:
            kwargs["formatter_class"] = argparse.RawDescriptionHelpFormatter

        if "usage" not in kwargs:
            kwargs["usage"] = "%(prog)s [options]"

        super(MongoArgumentParser, self).__init__(**kwargs)

        self.add_argument(
                "--host", default="localhost",
                help="host to connect to (default: %(default)s)")

        self.add_argument(
                "--port", default=27017, type=int,
                help="port to connect to (default: %(default)s)")

        self.add_argument(
                "--username", default="",
                help="username to authenticate with")

        self.add_argument(
                "--password", default="",
                help="password to authenticate with")

        self.add_argument(
                "--authenticationDatabase", default="database where user info is stored",
                help="password to authenticate with")

    def parse_args(self, *args, **kwargs):
        if "args" not in kwargs:
            kwargs["args"] = sophos.mongo.get_mongo_connection_args(*(self._services)) + sys.argv[1:]

        result = super(MongoArgumentParser, self).parse_args(*args, **kwargs)

        if result.username == "" and result.password != "":
            self.error("--username was not set but --password was")

        if result.username != "" and result.password == "":
            self.error("--username was set but --password was not")

        return result


class MongoAuthFailure(Exception):
    """Subclass of Exception raised when MongoDB authentication fails."""

    pass


def get_admin_database_connection(args):
    """Create a MongoDB client object from the given args and return the admin database object after connecting."""

    if args.username == "":
        client = pymongo.MongoClient(args.host, args.port, connect=True)
        admin_db = client.get_database("admin")
    else:
        client = pymongo.MongoClient(args.host, args.port, connect=False)
        admin_db = client.get_database("admin")
        try:
            if not admin_db.authenticate(args.username, args.password):
                raise MongoAuthFailure("authentication to %s:%d/admin failed" % (args.host, args.port))
        except pymongo.errors.OperationFailure as e:
            if e.details.get("codeName") == "AuthenticationFailed":
                raise MongoAuthFailure("authentication to %s:%d/admin failed" % (args.host, args.port))
            else:
                raise

    return admin_db


def sharding_is_enabled():
    """Return True if sharding is enabled, else False."""

    with open("/var/sophos/cookbooks/instance-attributes.json") as fp:
        attributes = json.load(fp)
        sharding_enabled = attributes.get("mongo", {}).get("sharding_enabled", "")
        return str(sharding_enabled).lower() == "true"


def get_mongo_conf_path():
    """
    Return path to mongos or mongod configuration file, depending on whether
    or not sharding is enabled for this instance.
    """

    with open("/opt/sophos/service") as fp:
        service_name = fp.readline().strip()

        if "client" in service_name:
            return MONGO_CLIENT_CONF_PATH
        elif "configsvr" in service_name:
            return MONGOD_CONF_PATH
        elif sharding_is_enabled():
            return MONGOS_CONF_PATH_FOR_MONGOD_INST
        else:
            return MONGOD_CONF_PATH

def read_mongos_conf(mongos_conf_path):
    """Read the mongos configuration information at the specified path"""

    with open(mongos_conf_path) as mfp:
        mongos_conf = yaml.safe_load(mfp)
        chef_conf = sophos.common.read_chef_attributes()

        key_file_path = mongos_conf["security"]["keyFile"]
        config_dir_path = os.path.dirname(key_file_path)
        replica_set_conf_path = os.path.join(config_dir_path, "replica-set.json")

        replica_set_conf = None
        with open(replica_set_conf_path) as rfp:
           replica_set_conf = json.load(rfp)

        cloud = chef_conf["sophos_cloud"]
        account = cloud["environment"]
        vpc = cloud["vpc_name"]

        cluster = chef_conf["mongos"]["replica_set"]["name"]

        aws = sophos.aws.AwsHelper()
        server = aws.instance_id()
        az = aws.availability_zone()

        return {
            "mongo": mongos_conf,
            "replica_set": replica_set_conf,
            "chef": chef_conf,
            "dimensions": {
                "account": account,
                "vpc_name": vpc,
                "cluster": cluster,
                "server": server,
                "application_data": "mongos",
                "az": az,
            },
        }


def read_mongo_conf(mongo_conf_path, attr_file_path=None):
    """
    Return dictionary of mongo configuration data, with main keys 'mongo',
    'replica_set', and 'chef'.

    Reads the configuration file specified in argument, replica-set.json from
    the directory containing the key file, and instance-attributes.json or
    attributes.json from /var/sophos/cookbooks.
    """

    with open(mongo_conf_path) as mfp:
        mongo_conf = yaml.safe_load(mfp)

        key_file_path = mongo_conf["security"]["keyFile"]
        config_dir_path = os.path.dirname(key_file_path)
        replica_set_conf_path = os.path.join(config_dir_path, "replica-set.json")

        with open(replica_set_conf_path) as rfp:
            replica_set_conf = json.load(rfp)

            chef_conf = sophos.common.read_chef_attributes()

            account = chef_conf["sophos_cloud"]["environment"]

            vpc_name = chef_conf["sophos_cloud"]["vpc_name"]

            application_data = chef_conf["sophos_cloud"]["application_data"]

            cluster = chef_conf["mongo"]["mongo_replica_set_name"]

            sharding_config = mongo_conf.get("sharding", {})
            is_configsvr = sharding_config.get("clusterRole") == "configsvr"
            is_client = chef_conf["sophos_cloud"]["application_name"] == "mongodb-client"

            # Use same nomenclature used in Logic Monitor groups.
            if is_configsvr:
                shard = "configsvr"
            elif is_client:
                shard = None
            else:
                shard = "shard%03d" % int(chef_conf["mongo"]["mongo_sharding_set_id"])

            if is_client:
                server = None
            else:
                server = "server%02d" % int(chef_conf["mongo"]["mongo_replica_set_instance"])

            return {
                "mongo": mongo_conf,
                "replica_set": replica_set_conf,
                "chef": chef_conf,
                "dimensions": {
                    "account": account,
                    "vpc_name": vpc_name,
                    "cluster": cluster,
                    "shard": shard,
                    "server": server,
                    "application_data": application_data,
                }
            }


def run_mongo_command(mongo_conf_data, command="/usr/bin/mongo", args=None):
    """Run mongo using port and admin user credentials specified in mongo_conf_data."""

    port = str(mongo_conf_data["mongo"]["net"]["port"])
    username = mongo_conf_data["replica_set"]["admin_username"]
    password = mongo_conf_data["replica_set"]["admin_password"]

    argv = [
        command,
        "--port", port,
        "-u", username,
        "-p", password,
        "--authenticationDatabase", "admin",
    ]

    if _is_ssl_required(mongo_conf_data):
        argv.append("--ssl")

        ssl_ca_file = _get_ssl_ca_file(mongo_conf_data)

        if ssl_ca_file:
            argv.append("--sslCAFile")
            argv.append(ssl_ca_file)

        if _are_invalid_ssl_certificates_allowed(mongo_conf_data):
            argv.append("--sslAllowInvalidCertificates")

        if _are_invalid_ssl_hostnames_allowed(mongo_conf_data):
            argv.append("--sslAllowInvalidHostnames")

    if args is not None:
        argv.extend(args)

    try:
        subprocess.check_call(argv)
    except KeyboardInterrupt:
        # Suppress stack trace when user hits Ctrl-C.
        # Report termination signal in exit status.
        sys.exit(128 + signal.SIGINT)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)


def get_mongo_client(mongo_conf_data):
    """Create and return mongo client connection to port specified in config data."""

    port = int(mongo_conf_data["mongo"]["net"]["port"])
    mongo_client = pymongo.MongoClient("localhost", port, connect=False)
    return mongo_client


def authenticate_as_admin(mongo_client, mongo_conf_data):
    """Authenticate against admin db, return admin db object or None."""

    admin_db = mongo_client.get_database("admin")

    username = mongo_conf_data["replica_set"]["admin_username"]
    password = mongo_conf_data["replica_set"]["admin_password"]
    if not admin_db.authenticate(username, password):
        return None

    return admin_db


def check_mongod(mongo_conf_data, stderr):
    """Check local mongod replica set, return True if it's healthy, else False."""

    try:
        try:
            subprocess.check_output(["/sbin/pidof", "mongod"])
        except subprocess.CalledProcessError:
            print >> stderr, "No 'mongod' process running on this machine."
            return False

        mongo_client = get_mongo_client(mongo_conf_data)

        admin_db = authenticate_as_admin(mongo_client, mongo_conf_data)
        if admin_db is None:
            print >> stderr, "Failed to authenticate against 'admin' database."
            return False

        replica_status = admin_db.command("replSetGetStatus")

        replica_set_name = replica_status["set"]

        primary_count = 0
        for member in replica_status["members"]:
            state_name = member["stateStr"]
            if state_name == "PRIMARY":
                primary_count += 1

        if primary_count == 0:
            print >> stderr, "Replica set %s: found no PRIMARY instance." % replica_set_name
            return False

        if primary_count > 1:
            print >> stderr, "Replica set %s: found multiple PRIMARY instances." % replica_set_name
            return False

        print >> stderr, "Replica set %s: OK" % replica_set_name
        return True

    except Exception as e:
        print >> stderr, "%s: %s" % (e.__class__.__name__, e.message)
        return False


def set_sharding_configuration(mongo_conf_data, stderr, balancer_start, balancer_stop, chunk_size):
    """Set sharding parameters via mongos."""

    try:
        mongo_client = get_mongo_client(mongo_conf_data)

        admin_db = authenticate_as_admin(mongo_client, mongo_conf_data)
        if admin_db is None:
            print >> stderr, "Failed to authenticate against 'admin' database."
            return False

        config_db = mongo_client.get_database("config")

        # Set balancer window.

        set_balancer_window = True
        if balancer_start is None or balancer_start == "":
            set_balancer_window = False
        if balancer_stop is None or balancer_stop == "":
            set_balancer_window = False

        balancer_timeout_ms = 60 * 1000

        if set_balancer_window:
            # Enable balancing.
            config_db.settings.update_one(
                    {"_id": "balancer"},
                    {"$set": {"activeWindow": {"start": balancer_start, "stop": balancer_stop}}},
                    upsert=True)
            # If we're outside the active window then this just enables balancing
            # without starting it.
            admin_db.command("balancerStart", maxTimeMS=balancer_timeout_ms)
        else:
            # Disable balancing.
            config_db.settings.update_one(
                    {"_id": "balancer"},
                    {"$unset": {"activeWindow": 1}})
            admin_db.command("balancerStop", maxTimeMS=balancer_timeout_ms)

        # Set chunk size.

        set_chunk_size = True
        if chunk_size is None or chunk_size == "":
            set_chunk_size = False

        if set_chunk_size:
            chunk_size = int(chunk_size)
            config_db.settings.save({"_id": "chunksize", "value": chunk_size})

    except Exception as e:
        print >> stderr, "%s: %s" % (e.__class__.__name__, e.message)
        return False


def get_mongod_health(mongod_conf_data):
    """Return health string for mongod process running on current instance."""

    pidfile_path = "/var/run/mongodb/mongod.pid"

    expected_program_path = "/usr/bin/mongod"

    (admin_db, health) = get_mongo_health(mongod_conf_data, pidfile_path, expected_program_path)

    if admin_db is None:
        return health

    try:
        # Check replica set status.

        replica_status = admin_db.command("replSetGetStatus")
        state_number = str(replica_status["myState"])
        state = MONGO_MEMBER_STATES.get(state_number, "UnrecognizedState(%s)" % state_number)

        # Report hidden secondaries as HIDDEN instead of SECONDARY.

        if state == "SECONDARY":
            replica_config = admin_db.command("replSetGetConfig")
            for i, status in enumerate(replica_status.get("members", [])):
                if status.get("self"):
                    config = replica_config["config"]["members"][i]
                    if config.get("hidden"):
                        state = "HIDDEN"
                        break

        return state

    except Exception as e:
        logging.error("%s", e.message, exc_info=1)
        return MONGO_HEALTH_MAY_HAVE_CRASHED


def get_mongos_health(mongos_conf_data):
    """Return health string for mongos process running on current instance."""

    pidfile_path = "/var/run/mongos/mongos.pid"

    expected_program_path = "/usr/bin/mongos"

    (admin_db, health) = get_mongo_health(mongos_conf_data, pidfile_path, expected_program_path)

    if admin_db is None:
        return health

    try:
        # Check replica set status.

        mongos_status = admin_db.command("listShards")
        mongos_shards = mongos_status["shards"]
        if mongos_shards is None or not isinstance(mongos_shards, list) or len(mongos_shards) == 0:
            return MONGOS_HEALTH_NO_SHARDS_FOUND

        return (MONGOS_HEALTH_HEALTHY % len(mongos_shards))

    except Exception as e:
        logging.error("%s", e.message, exc_info=1)
        return MONGO_HEALTH_MAY_HAVE_CRASHED



def get_mongo_health(mongo_conf_data, pidfile_path, expected_program_path):
    try:
        # No pidfile means either mongo never started or it stopped cleanly.
        if not os.path.exists(pidfile_path):
            logging.info("Cannot find pid file '%s'.", pidfile_path)
            return (None, MONGO_HEALTH_NOT_RUNNING)

        # Make sure the pidfile is not empty or corrupt.
        pid = None
        try:
            with open(pidfile_path) as pidfile:
                pid = int(pidfile.read().strip())
        except Exception as e:
            logging.error("%s", e.message, exc_info=1)
            return (None, MONGO_HEALTH_MAY_HAVE_CRASHED)

        # Make sure the process associated with the pid actually exists.
        program = None
        proc_exe_path = "/proc/%d/exe" % pid
        try:
            program = os.readlink(proc_exe_path)
        except Exception as e:
            logging.error("%s", e.message, exc_info=1)
            return (None, MONGO_HEALTH_MAY_HAVE_CRASHED)

        # Make sure the process associated with the pid is mongod/mongos.
        if program != expected_program_path:
            logging.error("Process file '%s' links to '%s', expected '%s'.", proc_exe_path, program, expected_program_path)
            return (None, MONGO_HEALTH_MAY_HAVE_CRASHED)

        logging.info("Found pid %s running executable '%s'.", pid, program)

        # We can see mongo is running, so now let's talk to it.

        mongo_client = get_mongo_client(mongo_conf_data)

        admin_db = authenticate_as_admin(mongo_client, mongo_conf_data)
        if admin_db is None:
            logging.error("Failed to authenticate against mongod 'admin' database.")
            return (None, MONGO_HEALTH_AUTH_FAILED)

        return (admin_db, None)

    except Exception as e:
        logging.error("%s", e.message, exc_info=1)
        return (None, MONGO_HEALTH_MAY_HAVE_CRASHED)


class MongosMetrics(object):
    """Metrics collected from the mongos process"""

    def __init__(self, mongos_conf_data):
        dims = mongos_conf_data["dimensions"]
        vpc_name = dims["vpc_name"]
        cluster = dims["cluster"]
        server = dims["server"]
        az = dims["az"]

        self.instance_dimensions = [{
            "Name": "A1VpcName",
            "Value": vpc_name
        }, {
            "Name": "A2Cluster",
            "Value": cluster
        }, {
            "Name": "A3Server",
            "Value": server
        }, {
            "Name": "A4AZ",
            "Value": az
        }]

        self.metrics = []

    def add_metric(self, dimensions, metric_name, value):
        log_prefix = " ".join(["%s=%s" % (d.get("Name"), d.get("Value")) for d in dimensions])
        logging.info("%s %r %r", log_prefix, metric_name, value)

        str_metric_name = str(metric_name)
        float_value = float(value)

        self.metrics.append({
            "Dimensions": dimensions,
            "MetricName": str_metric_name,
            "Value": float_value
        })

    def add_instance_metric(self, metric_name, value):
        self.add_metric(self.instance_dimensions, metric_name, value)


class MongodMetrics(object):
    """Metrics collected from the mongod process."""

    def __init__(self, mongod_conf_data, is_primary):
        self.is_primary = is_primary

        vpc_name = mongod_conf_data["dimensions"]["vpc_name"]

        cluster = mongod_conf_data["dimensions"]["cluster"]

        shard = mongod_conf_data["dimensions"]["shard"]

        server = mongod_conf_data["dimensions"]["server"]

        # Prefix dimensions names with A1, A2, etc. to force display order
        # in CloudWatch console to match the order given here.

        # Instance metrics are associated with a single replica set server.

        self.instance_dimensions = [{
            "Name": "A1VpcName",
            "Value": vpc_name
        }, {
            "Name": "A2Cluster",
            "Value": cluster
        }, {
            "Name": "A3Shard",
            "Value": shard
        }, {
            "Name": "A4Server",
            "Value": server
        }]

        # Primary metrics are instance metrics reports on a PRIMARY.
        # While redundant, they make it easy to view metrics without
        # worrying about which member has been elected primary.

        self.primary_dimensions = [{
            "Name": "A1VpcName",
            "Value": vpc_name
        }, {
            "Name": "A2Cluster",
            "Value": cluster
        }, {
            "Name": "A3Shard",
            "Value": shard
        }, {
            "Name": "A4Server",
            "Value": "PRIMARY"
        }]

        # Shard metrics are metrics associated with a single shard.
        # They are only collected on the PRIMARY configsvr instance.

        self.shard_dimensions = [{
            "Name": "A1VpcName",
            "Value": vpc_name
        }, {
            "Name": "A2Cluster",
            "Value": cluster
        }, {
            "Name": "A3Shard",
            "Value": shard
        }]

        # Cluster metrics are associated with the entire sharded cluster.
        # They are only collected on the PRIMARY configsvr instance.

        self.cluster_dimensions = [{
            "Name": "A1VpcName",
            "Value": vpc_name
        }, {
            "Name": "A2Cluster",
            "Value": cluster
        }]

        # Each metric is self-describing so we can keep a single list.
        self.metrics = []

    def add_metric(self, dimensions, metric_name, value):
        log_prefix = " ".join(["%s=%s" % (d.get("Name"), d.get("Value")) for d in dimensions])
        logging.info("%s %r %r", log_prefix, metric_name, value)

        str_metric_name = str(metric_name)
        float_value = float(value)

        self.metrics.append({
            "Dimensions": dimensions,
            "MetricName": str_metric_name,
            "Value": float_value
        })

    def add_instance_metric(self, metric_name, value):
        self.add_metric(self.instance_dimensions, metric_name, value)
        if self.is_primary:
            self.add_metric(self.primary_dimensions, metric_name, value)

    def add_shard_metric(self, metric_name, value):
        self.add_metric(self.shard_dimensions, metric_name, value)

    def add_cluster_metric(self, metric_name, value):
        self.add_metric(self.cluster_dimensions, metric_name, value)


def _add_disk_utilization_metrics(mongod_metrics):
    df_command = ["df", "--output=target,pcent,ipcent,fstype"]

    try:
        df_output = subprocess.check_output(df_command)

        df_lines = df_output.splitlines()
        df_lines.pop(0)
        for df_line in df_lines:
            mount_point, space_util, inode_util, fstype = df_line.split(None, 3)
            if fstype.endswith("tmpfs"):
                continue

            mount_point = mount_point.lstrip("/").replace("/", "_")
            if mount_point == "":
                mount_point = "ROOT"

            instance_dimensions = copy.copy(mongod_metrics.instance_dimensions)
            instance_dimensions += [{"Name": "Mount", "Value": mount_point}]

            mongod_metrics.add_metric(
                    instance_dimensions,
                    "DiskInodeUtilization",
                    inode_util.rstrip("%"))
            mongod_metrics.add_metric(
                    instance_dimensions,
                    "DiskSpaceUtilization",
                    space_util.rstrip("%"))

            if mongod_metrics.is_primary:
                primary_dimensions = copy.copy(mongod_metrics.primary_dimensions)
                primary_dimensions += [{"Name": "Mount", "Value": mount_point}]

                mongod_metrics.add_metric(
                        primary_dimensions,
                        "DiskInodeUtilization",
                        inode_util.rstrip("%"))
                mongod_metrics.add_metric(
                        primary_dimensions,
                        "DiskSpaceUtilization",
                        space_util.rstrip("%"))

    except Exception as e:
        logging.error("error getting disk utilization: %s", str(e), exc_info=1)


def _add_replica_set_metrics(mongod_metrics, admin_db, is_primary):
    replica_status = admin_db.command("replSetGetStatus")

    now = datetime.datetime.now()

    heartbeat_messages = []
    optime_date_values = []
    ping_ms_values = []

    this_member = None
    for member in replica_status["members"]:
        # Report instance metrics.
        if member.get("self", False):
            optime_age_delta = now - member["optimeDate"]
            optime_age_seconds = optime_age_delta.total_seconds()
            mongod_metrics.add_instance_metric("OptimeAgeSeconds", optime_age_seconds)
            mongod_metrics.add_instance_metric("State", member["state"])

        # Heartbeat messages are an instance metric even though they describe
        # the replica set (shard) because they can vary from instance to instance.
        last_heartbeat_message = member.get("lastHeartbeatMessage")
        if last_heartbeat_message is not None:
            heartbeat_messages.append(last_heartbeat_message)
            logging.info(
                    "_id: %s host: %s lastHeartbeatMessage: %s",
                    member.get("_id"),
                    member.get("host"),
                    last_heartbeat_message)

        # Only report shard metrics from perspective of the primary.
        if is_primary:
            optime_date = member.get("optimeDate")
            if optime_date is not None:
                optime_date_values.append(optime_date)

            ping_ms = member.get("pingMs")
            if ping_ms is not None:
                ping_ms_values.append(ping_ms)

    mongod_metrics.add_instance_metric("HeartbeatMessageCount", len(heartbeat_messages))

    if len(optime_date_values) > 0:
        optime_date_range_delta = max(optime_date_values) - min(optime_date_values)
        optime_date_range_seconds = optime_date_range_delta.total_seconds()
        mongod_metrics.add_shard_metric("OptimeDateRangeSeconds", optime_date_range_seconds)

    if len(ping_ms_values) > 0:
        ping_ms_max = max(ping_ms_values)
        mongod_metrics.add_shard_metric("PingMsMax", ping_ms_max)


def _add_server_status_metrics(mongod_metrics, admin_db):
    server_status = admin_db.command("serverStatus")

    global_lock = server_status.get("globalLock", {})
    active_clients = global_lock.get("activeClients", {})
    current_queue = global_lock.get("currentQueue", {})

    wired_tiger = server_status.get("wiredTiger", {})
    wired_tiger_cache = wired_tiger.get("cache", {})
    wired_tiger_txns = wired_tiger.get("concurrentTransactions", {})
    wired_tiger_session = wired_tiger.get("session", {})

    # For reference see the mongostat source code at https://github.com/mongodb/mongo-tools.git.

    # Report cache usage.

    cache_dirty_bytes = int(wired_tiger_cache.get("tracked dirty bytes in the cache", 0))
    cache_used_bytes = int(wired_tiger_cache.get("bytes currently in the cache", 0))
    cache_max_bytes = int(wired_tiger_cache.get("maximum bytes configured", 0))

    cache_dirty_percent = int(0.5 + (100.0 * cache_dirty_bytes / cache_max_bytes))
    cache_used_percent = int(0.5 + (100.0 * cache_used_bytes / cache_max_bytes))

    mongod_metrics.add_instance_metric("CacheDirtyPercent", cache_dirty_percent)
    mongod_metrics.add_instance_metric("CacheUsedPercent", cache_used_percent)

    # Report active readers and writers.

    active_readers = int(wired_tiger_txns.get("read", {}).get("out", 0))
    active_writers = int(wired_tiger_txns.get("write", {}).get("out", 0))

    mongod_metrics.add_instance_metric("ActiveReaders", active_readers)
    mongod_metrics.add_instance_metric("ActiveWriters", active_writers)

    # Report queued readers and writers.

    queued_readers = int(current_queue.get("readers", 0))
    queued_readers += int(active_clients.get("readers", 0))
    queued_readers -= active_readers
    if queued_readers < 0:
        queued_readers = 0

    queued_writers = int(current_queue.get("writers", 0))
    queued_writers += int(active_clients.get("writers", 0))
    queued_writers -= active_writers
    if queued_writers < 0:
        queued_writers = 0

    mongod_metrics.add_instance_metric("QueuedReaders", queued_readers)
    mongod_metrics.add_instance_metric("QueuedWriters", queued_writers)

    # Report open sessions.

    open_sessions = int(wired_tiger_session.get("open session count", 0))

    mongod_metrics.add_instance_metric("OpenSessions", open_sessions)


def _add_current_op_metrics(mongod_metrics, admin_db):
    # Use include_all=True to include inactive operations,
    # including idle connections and idle replication threads.
    current_op = admin_db.current_op(include_all=False)

    inprog = current_op.get("inprog", [])

    ops_active = len(inprog)
    ops_building_indexes = 0
    ops_external = 0
    ops_internal = 0

    for op in inprog:
        desc = op.get("desc", "")
        msg = op.get("msg", "")

        if msg.startswith("Index Build") or desc.startswith("repl index builder"):
            ops_building_indexes += 1

        if desc.startswith("conn"):
            ops_external += 1
        else:
            ops_internal += 1

    mongod_metrics.add_instance_metric("OpsActive", ops_active)
    mongod_metrics.add_instance_metric("OpsBuildingIndexes", ops_building_indexes)
    mongod_metrics.add_instance_metric("OpsExternal", ops_external)
    mongod_metrics.add_instance_metric("OpsInternal", ops_internal)


def _add_configsvr_metrics(mongod_metrics, mongod_client, mongos_client):
    config_db = mongod_client.get_database("config")

    # Don't call pymongo.database.Database.collection_names() simply to find
    # out if there is a config.collections collection, as that generates an
    # exclusive database lock on the config database.  Just check the chunks
    # count, since we have to be sharding a collection to have any chunks.
    if config_db.chunks.count() > 0:
        shards = []
        for shard_doc in config_db.shards.find():
            shards.append(shard_doc["_id"])

        for collection_doc in config_db.collections.find():
            ns = collection_doc["_id"]

            chunks_by_shard = { shard: 0 for shard in shards }
            for chunk_doc in config_db.chunks.find({"ns": ns}):
                shard = chunk_doc["shard"]
                chunks_by_shard[shard] += 1

            chunk_counts = chunks_by_shard.values()

            chunks_count = sum(chunk_counts)
            chunks_max = max(chunk_counts)
            chunks_min = min(chunk_counts)

            if chunks_count == 0:
                imbalance_ratio = 0
            else:
                imbalance_ratio = 1.0 * chunks_max / chunks_min

            namespace = ns.replace(".", "_")

            shard_dimensions = copy.copy(mongod_metrics.shard_dimensions)
            shard_dimensions += [{"Name": "Namespace", "Value": namespace}]

            mongod_metrics.add_metric(
                    shard_dimensions,
                    "ChunksCount",
                    chunks_count)

            mongod_metrics.add_metric(
                    shard_dimensions,
                    "ChunksMax",
                    chunks_max)

            mongod_metrics.add_metric(
                    shard_dimensions,
                    "ChunksMin",
                    chunks_min)

            mongod_metrics.add_metric(
                    shard_dimensions,
                    "ImbalanceRatio",
                    imbalance_ratio)

    if mongos_client is not None:
        try:
            mongos_admin_db = mongos_client.get_database("admin")
            balancer_status = mongos_admin_db.command("balancerStatus")

            balancer_enabled = balancer_status["mode"] == "full"

            balancer_running = balancer_status["inBalancerRound"]

            mongod_metrics.add_cluster_metric("BalancerEnabled", balancer_enabled)

            mongod_metrics.add_cluster_metric("BalancerRunning", balancer_running)

        except Exception as e:
            logging.error("error getting balancer status: %s", str(e), exc_info=1)


def _add_connection_metrics(mongos_metrics, admin_db):
    """add connection information to the supplied MongosMetrics object"""
    connPoolData = admin_db.command("connPoolStats")

    mongos_metrics.add_instance_metric("ConnectionsAvailable", connPoolData["totalAvailable"])
    mongos_metrics.add_instance_metric("ConnectionsInUse", connPoolData["totalInUse"])
    mongos_metrics.add_instance_metric("ConnectionsCreated", connPoolData["totalCreated"])

def _add_open_cursor_metrics(mongos_metrics, admin_db):
    """add open cursor information to the supplied MongosMetrics object"""
    server_status = admin_db.command("serverStatus")

    multi_cursors = server_status["metrics"]["cursor"]["open"]["multiTarget"]
    single_cursors = server_status["metrics"]["cursor"]["open"]["singleTarget"]

    mongos_metrics.add_instance_metric("OpenMultiTargetCursors", multi_cursors)
    mongos_metrics.add_instance_metric("OpenSingleTargetCursors", single_cursors)


def get_mongos_metrics(mongos_conf_data):
    """Return list of metric data for mongos installation on current instance."""

    mongos_client = get_mongo_client(mongos_conf_data)
    admin_db = authenticate_as_admin(mongos_client, mongos_conf_data)
    if admin_db is None:
        logging.error("Failed to authenticate against mongod 'admin' database.")
        return None

    mongos_metrics = MongosMetrics(mongos_conf_data)
    _add_connection_metrics(mongos_metrics, admin_db)
    _add_open_cursor_metrics(mongos_metrics, admin_db)

    return mongos_metrics.metrics


def get_mongo_metrics(mongod_conf_data, mongos_conf_data):
    """Return list of metric data for mongo installation on current instance."""

    metrics_list = []

    # Report mongod process health.

    health = get_mongod_health(mongod_conf_data)

    is_running = health not in [MONGO_HEALTH_NOT_RUNNING, MONGO_HEALTH_MAY_HAVE_CRASHED]
    is_healthy = health in MONGO_HEALTHY_MEMBER_STATES
    is_primary = health == "PRIMARY"

    mongod_metrics = MongodMetrics(mongod_conf_data, is_primary)

    mongod_metrics.add_instance_metric("IsHealthy", is_healthy)
    mongod_metrics.add_instance_metric("IsRunning", is_running)

    # TODO: Refactor to eliminate re-connection with mongo.

    mongod_client = get_mongo_client(mongod_conf_data)

    admin_db = authenticate_as_admin(mongod_client, mongod_conf_data)
    if admin_db is None:
        logging.error("Failed to authenticate against mongod 'admin' database.")
        return mongod_metrics

    _add_disk_utilization_metrics(mongod_metrics)

    _add_replica_set_metrics(mongod_metrics, admin_db, is_primary)

    _add_server_status_metrics(mongod_metrics, admin_db)

    _add_current_op_metrics(mongod_metrics, admin_db)

    if is_primary:
        sharding_config = mongod_conf_data["mongo"].get("sharding", {})
        is_configsvr = sharding_config.get("clusterRole") == "configsvr"
        if is_configsvr:
            mongos_client = None
            if mongos_conf_data is not None:
                mongos_client = get_mongo_client(mongos_conf_data)
                if not authenticate_as_admin(mongos_client, mongos_conf_data):
                    logging.error("Failed to authenticate against mongos 'admin' database.")
                    mongos_client = None
            _add_configsvr_metrics(mongod_metrics, mongod_client, mongos_client)

    # IDEA:
    #  Record elapsed time for a fixed query, e.g. db.collection.findOne() for some collection?
    #  Best to create a test collection specifically for this use case.

    return mongod_metrics.metrics


def _strip_wt(d):
    # Discard WiredTiger sections we don't care about.
    for section in "LSM cache_walk compression creationString metadata reconciliation type uri".split():
        d.pop(section, None)


def _strip_cs(d):
    # Discard collection stats sections we don't care about.
    d.pop("indexSizes")
    for ixd in d.get("indexDetails", {}).values():
        _strip_wt(ixd)
    _strip_wt(d.get("wiredTiger"))


def _read_proc_dict(path):
    ret = {}
    with open(path) as fp:
        data = fp.read()
        lines = data.splitlines()
        for line in lines:
            k, v = line.split(None, 1)
            ret[k] = v
    return ret


def get_mongod_statistics(mongod_conf_data):
    """Return dict containing statistics for mongo installation on current instance."""

    statistics = {
        "proc":             {},
        "top":              None,
        "replica_status":   None,
        "server_status":    None,
        "coll_stats":       {},
        "index_stats":      {},
        "latency_stats":    {},
    }

    statistics["proc"]["meminfo"] = _read_proc_dict("/proc/meminfo")
    statistics["proc"]["vmstat"] = _read_proc_dict("/proc/vmstat")

    mongod_client = get_mongo_client(mongod_conf_data)

    admin_db = authenticate_as_admin(mongod_client, mongod_conf_data)
    if admin_db is None:
        logging.error("Failed to authenticate against mongod 'admin' database.")
        return statistics

    # Collect op counts for each collection.
    # Reference: https://docs.mongodb.com/manual/reference/command/top/
    top = statistics["top"] = admin_db.command("top")

    # Collect replica set status information.
    # Reference: https://docs.mongodb.com/manual/reference/command/replSetGetStatus/
    statistics["replica_status"] = admin_db.command("replSetGetStatus")

    # Collect server process overview.
    # Reference: https://docs.mongodb.com/manual/reference/command/serverStatus/
    statistics["server_status"] = admin_db.command("serverStatus")

    # Get list of databases and collections from top output instead of by calling
    # pymongo.database.Database.collection_names(), as that method calls the
    # MongoDB listCollections function which acquires an exclusive read lock
    # on the database, which is disruptive under load.  The top command does
    # NOT acquire such a lock.

    collections_by_db = collections.defaultdict(set)
    database_names = mongod_client.list_database_names()
    for ns in top["totals"].keys():
        if "." not in ns:
            continue
        database_name, collection_name = ns.split(".", 1)
        if database_name not in database_names:
            continue
        if collection_name.startswith(("system.", "replset.", "$")):
            continue
        collections_by_db[database_name].add(collection_name)

    for database_name, collection_names in collections_by_db.items():
        db = mongod_client.get_database(database_name)

        # Don't bother calling the dbstats command if we're going to call
        # the collstats command for each collection in the database.
        # The dbstats command acquires an exclusive read lock on the
        # database, like listcollections, and the data it returns can
        # be reconstructed by summing the outputs from the collstat
        # commands, so long as we don't mind a little inconsistency
        # caused by summing collection data collected a few milliseconds
        # apart.
        #
        # No need to do that summing up here, we can post-process the
        # output when we download it.

        for collection_name in collection_names:
            ns = "%s.%s" % (database_name, collection_name)
            try:
                # Collect detailed collection storage statistics.
                # Reference: https://docs.mongodb.com/manual/reference/command/collStats/
                collection_stats = db.command("collstats", collection_name)

                # Strip out data we don't care about.
                _strip_cs(collection_stats)

                statistics["coll_stats"][ns] = collection_stats

            except pymongo.errors.OperationFailure as e:
                # We get the list of collections from the top command to avoid
                # taking the exclusive database read lock associated with the
                # listCollections operation.  Since collections may be dropped
                # without discarding their associated top counters, this means
                # our collection list can include dropped collections.
                # Running collstats against a dropped collection raises an exception.
                # We can safely ignore that exception.
                if "Collection [{}] not found".format(ns) in e.message:
                    pass
                else:
                    # Swallow exception, log it, and keep going.
                    logging.error("Namespace %r: collstats failed.", ns, exc_info=1)

            try:
                # Collect index statistics.
                # Reference: https://docs.mongodb.com/manual/reference/operator/aggregation/indexStats/
                pipeline = [{ "$indexStats": {} }]
                index_stats = db[collection_name].aggregate(pipeline)
                statistics["index_stats"][ns] = list(index_stats)
            except pymongo.errors.OperationFailure as e:
                # Swallow exception, log it, and keep going.
                logging.error("Namespace %r: $indexStats failed.", ns, exc_info=1)

            try:
                # Collect latency statistics.
                # Reference: https://docs.mongodb.com/manual/reference/operator/aggregation/collStats/#pipe._S_collStats
                pipeline = [{ "$collStats": { "latencyStats": { "histograms": True } } }]
                latency_stats = db[collection_name].aggregate(pipeline)
                statistics["latency_stats"][ns] = list(latency_stats)
            except pymongo.errors.OperationFailure as e:
                # Swallow exception, log it, and keep going.
                logging.error("Namespace %r: latencyStats failed.", ns, exc_info=1)

    return statistics


def _update_dict_adding_deltas(curr, prev):
    # We implement this by computing deltas for every numeric value,
    # regardless of whether or not it makes logical sense.

    # Use items() rather than iteritems() to avoid any issues from updating
    # curr as we loop over it.
    for k, v in curr.items():
        # Don't compute deltas of deltas of deltas ...
        if k.endswith("_delta"):
            continue

        # Recurse into dictionaries.
        if isinstance(v, dict):
            _update_dict_adding_deltas(v, None if prev is None else prev.get(k, {}))
            continue

        # Try to treat everything else as a number.
        try:
            curr_num = int(v)
            prev_num = int(0 if prev is None else prev.get(k, 0))
            delta = curr_num - prev_num
            curr[k + "_delta"] = delta
        except Exception:
            pass  # Just making best effort here.


def update_mongod_statistics_adding_deltas(timestamp, current, previous):
    """Update the current mongod statistics dict by adding entries for deltas since the previous dict."""

    # First compute the timestamp delta.

    delta_seconds = current["server_status"]["uptimeEstimate"]
    if previous is not None:
        delta_seconds -= previous["server_status"]["uptimeEstimate"]

    current["delta_seconds"] = delta_seconds

    # Next, compute the metric deltas.

    _update_dict_adding_deltas(
            current["server_status"],
            None if previous is None else previous["server_status"])

    _update_dict_adding_deltas(
            current["coll_stats"],
            None if previous is None else previous["coll_stats"])

    _update_dict_adding_deltas(
            current["top"]["totals"],
            None if previous is None else previous["top"]["totals"])

    return current


def _get_mongo_ssl_config(mongo_conf_data):
    return mongo_conf_data["mongo"]["net"]["ssl"]

def _is_ssl_required(mongo_conf_data):
    try:
        return _get_mongo_ssl_config(mongo_conf_data)["mode"] == "requireSSL"
    except KeyError as ex:
        return False

def _get_ssl_ca_file(mongo_conf_data):
    try:
        return _get_mongo_ssl_config(mongo_conf_data)["CAFile"]
    except KeyError as ex:
        return None

def _are_invalid_ssl_certificates_allowed(mongo_conf_data):
    try:
        return _get_mongo_ssl_config(mongo_conf_data)["allowInvalidCertificates"]
    except KeyError as ex:
        return False

def _are_invalid_ssl_hostnames_allowed(mongo_conf_data):
    try:
        return _get_mongo_ssl_config(mongo_conf_data)["allowInvalidHostnames"]
    except KeyError as ex:
        return False

def _are_ssl_connections_without_cert_allowed(mongo_conf_data):
    try:
        return _get_mongo_ssl_config(mongo_conf_data)["allowConnectionsWithoutCertificates"]
    except KeyError as ex:
        return False
