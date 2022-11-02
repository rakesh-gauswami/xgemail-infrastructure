#!/usr/bin/env python3
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4

# Version: 1.1

"""
Script to delete entries from VolumeTracker SimpleDB

Copyright 2022, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

from __future__ import print_function

import boto3
import argparse
import sys

def parse_command_line():
    parser = argparse.ArgumentParser(description="Delete attributes from the Simple DB Volume Tracker.")
    parser.add_argument("--account", "-a", dest='account', default='hub000dub', help="AWS Account.")
    parser.add_argument("--query", "-q", dest='query', default=False, help="ItemName() query. Example: CloudTest:xgemail:eu-west-1")
    return parser.parse_args()


class SdbHelper(object):
    def __init__(self, account, region):
        self.session = boto3.session.Session(profile_name=account, region_name=region)
        self.sdb = self.session.client('sdb')
        """:type: pyboto3.sns """

    def get_domain(self):
        # find the SDBVolumeTracker domain name
        domain_name = None
        for domain in self.sdb.list_domains()['DomainNames']:
            if domain.startswith('SDBVolumeTracker-SimpleDbDomain'):
                domain_name = domain
                return domain_name
            if domain.startswith('volume_tracker'):
                domain_name = domain
                return domain_name

        if not domain_name:
            print('\033[91mUnable to retrieve SDB Volume Tracker domain name. Exiting.\033[0m')
            sys.exit(1)

    def get_items(self, domain, query):
        select_params = {
            'SelectExpression': "SELECT * FROM `{domain}` WHERE itemName() LIKE '{query}%'".format(domain=domain, query=query),
            'ConsistentRead': True
        }
        resp = self.sdb.select(**select_params)
        if 'Items' in resp:
            return resp['Items']
        else:
            print('\033[31mNo matching records found. Exiting.\033[0m')
            exit(0)

    def delete_items(self, domain, items):
        self.sdb.batch_delete_attributes(
            DomainName=domain,
            Items=items
        )


if __name__ == "__main__":
    args = parse_command_line()

    if args.account.startswith(('eml', 'stn')):
        region = 'us-east-1'
    else:
        region = 'us-west-2'

    print('Account:\033[35m {} \033[0m'.format(args.account))
    print('Region:\033[35m {} \033[0m'.format(region))
    sdb_helper = SdbHelper(account=args.account, region=region)
    domain = sdb_helper.get_domain()
    print('Volume Tracker Domain:\033[35m {} \033[0m'.format(domain))
    items = sdb_helper.get_items(domain=domain, query=args.query)

    print('\033[94mVolume Tracker Items that match your query: {}\033[93m')
    for item in items:
        print(item['Name'])
    if len(items) > 25:
        print('\033[91mYour search returned more than 25 results which is the max that we can batch delete.\033[0m')
        exit(1)
    answer = input('\033[92mVerify these values are correct and type \033[35mDELETE\033[92m to continue. ')
    if answer == 'DELETE':
        print('\033[32mDeleting Records.\033[0m')
        delete = sdb_helper.delete_items(domain=domain, items=items)
    else:
        print('\033[33mExiting without deleting any records.\033[0m')
        sys.exit(0)
