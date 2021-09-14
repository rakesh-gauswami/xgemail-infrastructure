#!/usr/bin/env python3
# vim: autoindent expandtab shiftwidth=4 filetype=python

"""
Create missing ansible common vars files for all PoP accounts.

Example:
    %(prog)s ../ansible
"""

import argparse
import base64
import collections
import datetime
import hashlib
import os
import secrets
import signal
import uuid
import yaml

import supported_environment

def main():
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    args = parse_command_line()
    process(args)

def parse_command_line():
    doclines = __doc__.strip().splitlines()
    description = doclines[0]
    epilog = ("\n".join(doclines[1:])).strip()

    parser = argparse.ArgumentParser(
            description=description,
            epilog=epilog,
            formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
            "dir",
            help="ansible root directory.")

    return parser.parse_args()

def random_string(n):
    random_bytes = secrets.token_bytes(n)
    base64_bytes = base64.b64encode(random_bytes)
    decoded = base64_bytes.decode("utf-8")
    return decoded

def create_iapi_vaulted():
    # Unsure how these are normally calculated, but this code generates
    # the same form as existing properties.

    auth_id = str(uuid.uuid1())

    h = hashlib.sha256()
    h.update(os.urandom(128))
    auth_token = h.hexdigest()

    return {
        "iapi_vaulted": {
            "authId": auth_id,
            "authToken": auth_token,
        }
    }

def create_logic_monitor_config():
    return {
        "logic_monitor_config": {
            "is_active": False
        }
    }

def create_mongo_users_vaulted():
    return {
        "vault_mongo_users": {}
    }

def create_mongo_vars():
    timestamp = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
    return {
        "mongo_admin_username": f"{timestamp}-admin-{random_string(6)}",
        "mongo_client_username": f"{timestamp}-client-{random_string(6)}",
    }

def create_mongo_vars_vaulted():
    return {
        "vault_mongo_admin_password": random_string(188),
        "vault_mongo_client_password": random_string(188),
        # MongoDB considers '=' to be an invalid character in a key file.
        "vault_mongo_shared_secret": random_string(755).replace("=", ""),
    }

def create_redis_core_cluster_vars_vaulted():
    h = hashlib.sha384()
    h.update(os.urandom(128))
    token = h.hexdigest()
    return {
        "vault_redis_core_cluster_token": token,
    }

def create_snmp_credentials():
    return {
        "snmp_username": f"snmp--{random_string(16)}"
    }

def create_snmp_credentials_vaulted():
    return {
        "vault_snmp_password": random_string(20),
    }

CREATE_DATA_FUNCTIONS = {
    "iapi_vaulted.yml": create_iapi_vaulted,
    "logic_monitor_config.yml": create_logic_monitor_config,
    "mongo-users_vaulted.yml": create_mongo_users_vaulted,
    "mongo-vars.yml": create_mongo_vars,
    "mongo-vars_vaulted.yml": create_mongo_vars_vaulted,
    "redis-core-cluster-vars_vaulted.yml": create_redis_core_cluster_vars_vaulted,
    "snmp_credentials.yml": create_snmp_credentials,
    "snmp_credentials_vaulted.yml": create_snmp_credentials_vaulted,
}

def process(args):
    skipped = 0
    created = 0

    new_vaulted_paths = collections.defaultdict(list)
    new_dirs = set()

    print("creating files relative to", os.path.abspath(args.dir))
    print()

    account_names = supported_environment.SUPPORTED_ENVIRONMENT.get_pop_account_names()

    for account_name in account_names:
        account = supported_environment.SUPPORTED_ENVIRONMENT.get_pop_account(account_name)
        deployment_environment = account.get_deployment_environment()
        primary_region = account.get_primary_region()
        account_type = account.get_account_type()

        account_dir = os.path.join(
                args.dir, "roles", "common", "vars",
                deployment_environment, primary_region, account_type, account_name)

        os.makedirs(account_dir, exist_ok=True)

        for filename, create_data_function in CREATE_DATA_FUNCTIONS.items():
            path = os.path.join(account_dir, filename)

            if os.path.exists(path):
                print("skipping", path, "(it already exists)")
                skipped += 1
                continue

            print("creating", path, "...")
            d = create_data_function()
            with open(path, "w") as f:
                yaml.dump(d, f, explicit_start=True, explicit_end=True, sort_keys=True)
                pass

            if filename.endswith("_vaulted.yml"):
                new_vaulted_paths[deployment_environment].append(path)

            new_dirs.add(account_dir)

            created += 1

    print()
    print("skipped", skipped, "file(s)")
    print("created", created, "file(s)")

    if len(new_vaulted_paths) > 0:
        print()
        print("REMEMBER to run ansible-vault encrypt on these new vaulted files:")
        for deployment_environment, paths in new_vaulted_paths.items():
            print()
            print(f"Using vault key for {deployment_environment}:")
            for path in paths:
                print("-", path)

    if len(new_dirs) > 0:
        print()
        print("REMEMBER to run git add on new files in these directories:")
        for dirpath in sorted(new_dirs):
            print("-", dirpath)

    print()


if __name__ == "__main__":
    main()
