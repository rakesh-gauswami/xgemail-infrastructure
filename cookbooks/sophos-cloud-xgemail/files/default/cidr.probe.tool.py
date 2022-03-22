#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2022, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import argparse
import base64
import boto3
import requests
import sys
import urllib3
import json
import pip
import os
import logging

MAIL_PIC_RESPONSE_TIMEOUT = 30
ERROR_ENTRIES_PATH = '/tmp/deliveryIpType-errors.txt'

logging.basicConfig(
    datefmt="%Y-%m-%d %H:%M:%S",
    format="%(asctime)s " + " %(levelname)s %(message)s",
    level=logging.INFO,
    stream=sys.stdout)

try:
    from prettytable import PrettyTable
except ImportError:
    pip.main(['install', 'PrettyTable'])
    from prettytable import PrettyTable

def get_parsed_args(parser):
    parser.add_argument('--region', default = 'eu-west-1', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2','ap-northeast-1','ap-southeast-2','ca-central-1'], help = 'AWS region', required = True)
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'QA', 'PROD','INF'], help = 'AWS environment', required = True)
    parser.add_argument('--perform_probe', required=False, help="This option is to fetch the existing domains")
    parser.add_argument('--update_ip_type', required=False, help="This option is to call update delivery ip type API")
    parser.add_argument('--last_domain', help="If this parameter is specified, fetches domains that come after the specified domain", required = False)
    parser.add_argument('--no_of_domains', type=int, default=10, help="Number of domains")
    parser.add_argument('--file', help = 'Pass a json file ', required = False)

    args = parser.parse_args()
    return args

def get_passphrase(bucket, mail_pic_auth):
    s3 = boto3.client('s3')
    passphrase = s3.get_object(Bucket = bucket, Key = mail_pic_auth)
    return base64.b64encode('mail:' + passphrase['Body'].read())

def get_domain_and_status_from_file(args):
    domain_and_iptype_dict = {}
    if args.file:
        file_name = args.file
        if os.stat(file_name).st_size <= 3:
            logging.info("No records found in json file.Exiting..")
            exit()
        with open(file_name, 'r') as json_file:
            json_object = json.load(json_file)
            for record in json_object:
                if record['smtp_command'] == 'RCPTTO' and record['smtp_status'] == 250:
                    domain_and_iptype_dict[record['domain_name']] = "CIDR"
    else:
        logging.info("Aborting... please use --file { .json file }")
        return None
    return domain_and_iptype_dict

def update_delivery_ip_type_request_api(domain_and_iptype_dict,args):
    pic_fqdn = 'mail-cloudstation-{0}.{1}.hydra.sophos.com'.format(args.region, args.env.lower())
    mail_pic_api_auth = 'xgemail-{0}-mail'.format(args.region)
    connections_bucket = 'cloud-{0}-connections'.format(args.env.lower())
    mail_pic_api_url = 'https://{0}/mail/api/xgemail'.format(pic_fqdn)
    headers = {
        'Authorization': 'Basic ' + get_passphrase(connections_bucket, mail_pic_api_auth),
        'Content-Type': 'application/json'
    }
    failed_result = []
    for domain_name, ip_type in domain_and_iptype_dict.items():
        url = mail_pic_api_url + '/domains/{0}/{1}'.format(domain_name,ip_type)
        urllib3.disable_warnings(urllib3.exceptions.SecurityWarning)
        response = requests.post(
            url,
            headers = headers,
            timeout = MAIL_PIC_RESPONSE_TIMEOUT,
        )
        if response.ok:
            ''
        else:
            failed_result.append(domain_name)

    if len(failed_result) == 0:
        logging.info("Successfully submitted updateDeliveryIpType requests, response-  %s", response)
    else:
        logging.info("The list of domains that are not successfully updated can be found in /tmp/deliveryIpType-errors.txt")
        write_error_file(failed_result)
    return response

def write_error_file(failed_result):

    t = PrettyTable(['Update Failed Domains'])
    t.align = 'l'

    for cur_entry in failed_result:
        t.add_row([cur_entry])

    with open(ERROR_ENTRIES_PATH, 'w') as write_file:
        write_file.write(t.get_string())


def get_domains(last_domain, no_of_domains):
    pass


if __name__ == '__main__':
    try:
        arg_parser = argparse.ArgumentParser(description='Update deliveryIpType Request')
        parsed_args = get_parsed_args(arg_parser)
        perform_probe = parsed_args.perform_probe
        update_ip_type = parsed_args.update_ip_type
        last_domain = parsed_args.last_domain
        no_of_domains = parsed_args.no_of_domains
        if update_ip_type == 'update_ip_type':
            logging.info("Reading data from json file and creating domainName and deliveryIpType dictionary..!!")
            domain_and_iptype_dict = get_domain_and_status_from_file(parsed_args)
            logging.info("Sending request to update deliveryIpType for collected domains..!!")
            result = update_delivery_ip_type_request_api(domain_and_iptype_dict,parsed_args)
            if result is None or not result:
                arg_parser.print_help(sys.stderr)
                logging.info("Process Completed..!!")
                sys.exit(1)
        elif perform_probe == 'perform_probe':
            logging.info("Collecting domains..!!")
            get_domains(last_domain, no_of_domains)
        else:
            print("Incorrect option provided, please provide option based on the operation you want to perform - perform_prob or update_ip_type ")
            exit()
    except Exception as e:
        logging.error("An error occurred -  %s", e.message, exc_info=1)
        sys.exit(1)
    logging.info("Process Completed..!!")
