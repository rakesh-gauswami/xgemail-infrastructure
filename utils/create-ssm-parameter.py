#!/usr/bin/env python

"""
Add a secure (kms encrypted) AWS SSM Parameter to the system.

AWS Systems Manager Parameter Store provides secure,
hierarchical storage for configuration data management and secrets management.
You can store data such as passwords, database strings, and license codes as parameter values.
You can store values as plain text or encrypted data.
You can then reference values by using the unique name
that you specified when you created the parameter.

Copyright 2018, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import boto3
import argparse
import getpass


def parse_command_line():
    parser = argparse.ArgumentParser(
        description='Add a secure (kms encrypted) AWS SSM Parameter to the system.')
    parser.add_argument('--account', '-a', dest='account', default=getpass.getuser(), required=False, help='The AWS account where you want to add the parameter. Default: $USER')
    parser.add_argument('--region', '-r', dest='region', default='us-west-2', choices=[
        'eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-1', 'us-east-2'], required=False, help='The AWS region where you want to add the parameter. Default: us-west-2')

    return parser.parse_args()


def get_kms_key_id(kms_key_alias, client):
    for alias in client.list_aliases()['Aliases']:
        if kms_key_alias == alias['AliasName']:
            return alias['TargetKeyId']
    return None


if __name__ == '__main__':

    args = parse_command_line()

    parameter_name = raw_input("The fully qualified name of the SSM Parameter that you want to add to the system: ")
    parameter_value = getpass.getpass(prompt='SSM Parameter Value: ')
    parameter_description = raw_input("Type a description to help you identify parameters and their intended use: ")

    session = boto3.session.Session(region_name=args.region)
    kms = session.client('kms')
    ssm = session.client('ssm')

    kms_key_id = get_kms_key_id('alias/cloud-' + args.account + '-connections', kms)

    try:
        ssm.put_parameter(
            Name=parameter_name,
            Description=parameter_description,
            Value=parameter_value,
            Type='SecureString',
            KeyId=kms_key_id,
            Overwrite=True,
        )
        print("Successfully created {} in Parameter Store.".format(parameter_name))
    except Exception as e:
        print("Unable to create parameter {0} in Parameter Store. Exception: {1}".format(parameter_name, e))