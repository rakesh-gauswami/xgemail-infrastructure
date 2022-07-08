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
import os
import logging
import shutil
import smtplib
import socket
from smtplib import SMTPDataError
from smtplib import SMTPException
from smtplib import SMTPSenderRefused
from smtplib import SMTPRecipientsRefused

MAIL_FROM = "do-not-reply@cloud.sophos.com"
MAIL_PIC_RESPONSE_TIMEOUT = 30
ERROR_ENTRIES_PATH = '/tmp/cidr.probe.tool.errors.txt'
PROBE_RESPONSE_FILE = '/tmp/cidr.probe.response.json'

sys.tracebacklimit = 0
passphrase = ""

logging.basicConfig(
    datefmt="%Y-%m-%d %H:%M:%S",
    format="%(asctime)s " + " %(levelname)s %(message)s",
    level=logging.INFO,
    stream=sys.stdout)

def get_parsed_args(parser):
    parser.add_argument('--region', default = 'eu-west-1', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'], help = 'AWS region', required = True)
    parser.add_argument('--env', default = 'DEV', choices=['DEV', 'QA', 'PROD','INF'], help = 'AWS environment', required = True)
    parser.add_argument('--perform_probe', required=False, action='store_true', help="This option is to perform smtp probe for domain still using legacy delivery servers.")
    parser.add_argument('--update_ip_type', required=False, action='store_true', help="This option is to update delivery ip type for domains which passed smtp probe.")
    parser.add_argument('--last_domain', help="If this parameter is specified, fetches domains that come after the specified domain", required = False, default="")
    parser.add_argument('--no_of_domains', type=int, default=10, help="Number of domains")
    parser.add_argument('--file', help = 'Pass a json file ', required = False)

    args = parser.parse_args()
    return args

def get_mail_pic_url(args):
    pic_fqdn = 'mail-cloudstation-{0}.{1}.hydra.sophos.com'.format(args.region, args.env.lower())
    return 'https://{0}/mail/api/xgemail'.format(pic_fqdn)


def get_passphrase(args):
    global passphrase
    if passphrase == "":
        mail_pic_api_auth_key = 'xgemail-{0}-mail'.format(args.region)
        connections_bucket = 'cloud-{0}-connections'.format(args.env.lower())
        s3 = boto3.client('s3')
        secret = s3.get_object(Bucket = connections_bucket, Key = mail_pic_api_auth_key)
        passphrase = base64.b64encode('mail:' + secret['Body'].read())
        return passphrase
    else:
        return passphrase

def get_domain_and_status_from_file(args):
    domain_and_iptype_dict = {}
    if args.file:
        file_name = args.file
        if os.stat(file_name).st_size <= 3:
            logging.info("No records found in json file. Exiting...")
            exit()
        with open(file_name, 'r') as json_file:
            json_object = json.load(json_file)
            for record in json_object:
                if "domain_name" not in record:
                    logging.error("domain_name field is not available,continuing with next record")
                    continue
                elif "smtp_command" in record and "smtp_status" in record:
                    if record['smtp_command'] == 'rcptto' and record['smtp_status'] == 250:
                        domain_and_iptype_dict[record['domain_name']] = "CIDR"
                else:
                    logging.error("smtp_command or smtp_status field not available for domain - %s, continuing with next record", record['domain_name'])
                    continue
    else:
        logging.info("Aborting... please use --file { .json file }")
        return None
    return domain_and_iptype_dict

def update_delivery_ip_type(domain_and_iptype_dict,args):
    mail_pic_api_url = get_mail_pic_url(args)
    headers = {
        'Authorization': 'Basic ' + get_passphrase(args),
        'Content-Type': 'application/json'
    }
    failed_result = []
    for domain_name, ip_type in domain_and_iptype_dict.items():
        logging.info("Updating delivery ip type to {0} for domain {1}".format(ip_type, domain_name))
        url = mail_pic_api_url + '/domains/{0}/{1}'.format(domain_name,ip_type)
        urllib3.disable_warnings(urllib3.exceptions.SecurityWarning)
        response = requests.post(
            url,
            headers = headers,
            timeout = MAIL_PIC_RESPONSE_TIMEOUT,
        )
        if response.status_code != 200:
            failed_result.append(domain_name)

    if len(failed_result) > 0:
        logging.info("The list of domains that are not successfully updated can be found in /tmp/cidr.probe.tool.errors.txt")
        write_error_file(failed_result)

def write_error_file(failed_result):
    json_string = json.dumps(failed_result, indent=4)
    with open(ERROR_ENTRIES_PATH, 'w') as write_file:
        write_file.write(json_string)

def perform_smtp_probe(mta_host, mta_port,from_addr, to_addr):
    server = smtplib.SMTP(mta_host, mta_port, socket.getfqdn(), 5)
    server.ehlo_or_helo_if_needed()
    esmtp_opts = []
    rcpt_options=[]

    if server.does_esmtp:
        if server.has_extn('starttls'):
            logging.info('STARTTLS supported')
            server.starttls()
            server.ehlo_or_helo_if_needed()

    (code, resp) = server.mail(from_addr, esmtp_opts)
    if code != 250:
        server.quit()
        return (code, resp, 'mailfrom')

    (code, resp) = server.rcpt(to_addr, rcpt_options)
    if (code != 250):
        logging.info("Response:[{}]".format(resp))
        return (code, resp, 'rcptto')

    server.quit()
    return (code, resp, 'rcptto')

def build_probe_error_record(domain, error_response):
    probe = {}
    probe['domain_name'] = domain
    probe['error_response'] = error_response
    return probe

def get_domains(last_domain, no_of_domains,args):
    mail_pic_api_url = get_mail_pic_url(args)
    headers = {
        'Authorization': 'Basic ' + get_passphrase(args),
        'Content-Type': 'application/json'
    }

    #Take a backup of transport
    logging.debug("Taking a backup of transport file")
    tmp_transport_file = "/tmp/transport"
    shutil.copyfile("/etc/postfix-cd/transport", tmp_transport_file)
    #Read from backup and build dict of domain name to destination server.
    domain_detail_dict = {}
    with open(tmp_transport_file) as file:
        for line in file:
            line_parts = line.split();
            domain = line_parts[0]
            transport = line_parts[1]

            transport_parts = transport.split(':')
            protocol = transport_parts[0]
            server = transport_parts[1]
            if server.startswith("["):
                server = server[1:-1]
            if len(transport_parts) == 3:
                port = transport_parts[2]
            else:
                port = 25
            domain_info = {}
            domain_info['server'] = server
            domain_info['port'] = port
            domain_detail_dict[domain] = domain_info


    #If delivery ip type is not set or LEGACY, perform SMTP check.
    count=0
    probe_details=[]
    for domain in sorted(domain_detail_dict):
        if count >= no_of_domains:
            break;
        logging.debug('Checking domain {} with details  {}'.format(domain, domain_detail_dict[domain]))

        if last_domain != "" and domain <= last_domain:
            continue

        #For each domain, get current delivery ip type by calling mail pic api.
        get_delivery_ip_type_response = requests.get(
            mail_pic_api_url + '/domains/' + domain + '/deliveryIpType',
            headers = headers,
            timeout = MAIL_PIC_RESPONSE_TIMEOUT
        )

        if get_delivery_ip_type_response.status_code != 200:
            probe_details.append(build_probe_error_record(domain, 'Could not get IP type. ' +  get_delivery_ip_type_response.content))
            continue
        logging.info('Domain {} Ip Type {}'.format(domain, get_delivery_ip_type_response.content))

        if get_delivery_ip_type_response.content == 'CIDR':
            continue

        get_address_parameters = {
            'domain' : domain
        }
        get_address_response = requests.get(
            mail_pic_api_url + '/v2/addresses',
            headers = headers,
            params = get_address_parameters,
            timeout = MAIL_PIC_RESPONSE_TIMEOUT
        )
        if get_address_response.status_code != 200:
            probe_details.append(build_probe_error_record(domain, 'Could not get recipient address. ' +  get_address_response.content))
            continue

        if 'addresses' not in get_address_response.json():
            continue
        
        if len(get_address_response.json()['addresses']) == 0:
            logging.info('No address found in response {0}'.format(get_address_response.json()))
            continue

        to_addr = get_address_response.json()['addresses'][0]
        destination = domain_detail_dict[domain]['server']
        port = domain_detail_dict[domain]['port']
        count = count + 1
        probe = {}
        probe['domain_name'] = domain
        probe['destination_server'] = destination
        probe['destination_port'] = port

        try:
            logging.debug("Domain [{}] Address [{}] Destination [{}] Port [{}]".format(domain, to_addr, destination, port))
            (code, resp, cmd) = perform_smtp_probe(destination, port, MAIL_FROM, to_addr)
            logging.debug("Domain [{}] Code [{}] Response [{}]".format('devtest.jpsbim.com', code, resp))
            probe['smtp_command'] = cmd
            probe['smtp_response'] = resp
            probe['smtp_status'] = code
        except Exception as e:
            logging.exception("CIDR probe failed for Domain: [{}] Error: [{}]".format(domain, str(e)), exc_info=0)
            probe['error_response'] = str(e)
        probe_details.append(probe)
    logging.info('Result:{}'.format(json.dumps(probe_details)))
    with open(PROBE_RESPONSE_FILE, 'w') as f:
        f.write('{0}'.format(json.dumps(probe_details)))

if __name__ == '__main__':
    try:
        arg_parser = argparse.ArgumentParser(description='Update deliveryIpType Request')
        parsed_args = get_parsed_args(arg_parser)
        perform_probe = parsed_args.perform_probe
        update_ip_type = parsed_args.update_ip_type
        last_domain = parsed_args.last_domain
        no_of_domains = parsed_args.no_of_domains
        if update_ip_type:
            logging.info("Reading data from json file and creating domainName and deliveryIpType dictionary...")
            domain_and_iptype_dict = get_domain_and_status_from_file(parsed_args)
            logging.info("Sending request to update deliveryIpType for collected domains...")
            update_delivery_ip_type(domain_and_iptype_dict, parsed_args)
        elif perform_probe:
            logging.info("Collecting domains..!!")
            get_domains(last_domain, no_of_domains, parsed_args)
        else:
            print("Incorrect option provided, please provide option based on the operation you want to perform - perform_prob or update_ip_type ")
            exit()
    except Exception as e:
        logging.error("An error occurred -  %s", e.message, exc_info=0)
        sys.exit(1)
    logging.info("Process Completed...")