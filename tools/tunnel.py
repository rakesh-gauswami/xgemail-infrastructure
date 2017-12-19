#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import logging
import argparse
import getpass

#External packages
from sshtunnel import SSHTunnelForwarder
from getch import pause

#External packages
try:
    from sshtunnel import SSHTunnelForwarder
    from getch import pause
except ImportError as e:
    if e.message.startswith("ImportError: No module named "):
        print >> sys.stderr, e.message
        print >> sys.stderr, "Run 'sudo -i pip install %s' then try again." % e.message.split()[-1]
        sys.exit(1)
    else:
        raise

def parse_command_line():
    parser = argparse.ArgumentParser(description=" ")
    parser.add_argument("--log_level", "-L", default='INFO',
                        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
                        help="A log level for the python logger")
    parser.add_argument("--region", "-R", required=True,
                        help="Region you want to connect to")
    parser.add_argument("--env", "-E", default='dev',
                        choices=['dev','dev3','qa','inf','prod'],
                        help="Environment you are connecting to")
    parser.add_argument("--vpc", "-V", default="station",
                        choices=['station','hub','mail'],
                        help="VPC You are contacting.")
    parser.add_argument("--service", "-S", default="JMX",
                        choices=['JMX','KIBANA','ES'],
                        help="Which service are you tunneling to")
    parser.add_argument("--password", "-p", action='store_true',
                        help="Do we want to use a password instead of a private key")
    parser.add_argument("--port", "-P", default=8080,
                        help="Local port you want to use")

    return parser.parse_args()

def setup_logging(args):
    # Setup logging
    numeric_level = getattr(logging, args.log_level.upper(), None)
    logging.basicConfig(format='%(asctime)s [%(levelname)s] %(message)s', level=numeric_level)
    logging.debug("Command line arguments are (%s)", args)

# MAPPINGS
VPC_MAP = {
    "station"   : "CloudStation",
    "hub"       : "CloudHub",
    "mail"      : "CloudMail",
}

REMOTE_PORT_MAP = {
    "ES"        :   "8080",
    "JMX"       :   "8080",
    "KIBANA"    :   "8080",
}

INSTANCE_MAP = {
    "ES"        :   {
        "hub"       :   "monitor-logging",
        "station"   :   "monitor-logging",
        "mail"      :   "monitor-logging",
    },
    "JMX"       :  {
        "hub"       :   "hub",
        "station"   :   "core",
        "mail"      :   "submit",
    },
    "KIBANA"    :  {
        "hub"       :   "elk-kibana",
        "station"   :   "elk-kibana",
        "mail"      :   "elk-kibana",
    },
}

DNS_SUFFIX = {
    'JMX' : "-%s-%s.%s.hydra.sophos.com",
    'KIBANA' : ".%s.%s.%s.hydra.sophos.com",
    'ES' : ".%s.%s.%s.hydra.sophos.com",
}

HOPPER_MAP = {
    "dev"       :   "hopper-dev",
    "dev3"      :   "hopper-dev",
    "inf"       :   "hopper-dev",
    "qa"        :   "hopper-qa",
    "prod"      :   "hopper-prod",
}

def main(args):
    hopper = "%s.cloud.sophos" % (HOPPER_MAP[args.env])
    dns_suffix = DNS_SUFFIX[args.service] % (
        VPC_MAP[args.vpc],
        args.region,
        args.env,
    )

    remote_port = REMOTE_PORT_MAP[args.service]

    password = get_password(hopper) if args.password else ""

    tunnel_helper(hopper, INSTANCE_MAP[args.service][args.vpc], dns_suffix, args.port, remote_port, password)


def get_password(hopper):
    return getpass.getpass("Enter password for %s: " % (hopper))


def helper_message(instance, local_port):
    URLs = {
        'core'              : '/core/jmx/',
        'hub'               : '/jmx/',
        'submit'            : '/submit/jmx/',
        'elk-kibana'        : '/',
        'monitor-logging'   : '/_plugin/head',
    }

    return "Please use http://localhost:%s%s to connect to this service" % (local_port,URLs[instance])


def tunnel_helper(hopper,instance,dns_suffix,local_port,remote_port,password):
    #cmd = 'ssh -L %s:%s:%s %s' % (local_port, instance, remote_port, hopper)
    remote_address = "%s%s" % (instance,dns_suffix)
    logging.info('REMOTE LOCATION: %s', remote_address)

    # The below call will fail on a VPN because it doesn't know what to do with VPN interface in _get_local_interfaces.
    # If you are just trying to bind to localhost you can work around this by editing around like 1378 of sshtunnel.py (in_get_local_interfaces)
    # just replace 'local_if = socket.gethostbyname_ex(skt)[-1]' with local_if = []

    with SSHTunnelForwarder(
        ssh_address_or_host=(hopper, 22),
        ssh_username=getpass.getuser(),
        ssh_password=password,
        remote_bind_address=(remote_address, int(remote_port)),
        local_bind_address=('127.0.0.1', int(local_port))
    ) as server:
        # Scrub password
        password = ""
        print(helper_message(instance, server.local_bind_port))
        pause("Press any key to exit to end the ssh tunnel")


if __name__ == "__main__":
    args = parse_command_line()
    setup_logging(args)
    main(args)
