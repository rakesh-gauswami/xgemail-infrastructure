#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Polls XGEMAIL PIC for a list of customer domains
#
# Copyright: Copyright (c) 1997-2016. All rights reserved.
# Company: Sophos Limited or one of its affiliates.

import boto3
import base64
import json
import os
import requests
import subprocess
import sys
import logging
from logging.handlers import SysLogHandler

# Constants
PIC_FQDN = 'mail-cloudstation-eu-west-1.dev.hydra.sophos.com'
MAIL_PIC_RESPONSE_TIMEOUT = 60
MAIL_PIC_API_AUTH = 'xgemail-eu-west-1-mail'
CONNECTIONS_BUCKET = 'cloud-dev-connections'

# logging to syslog setup
logging.getLogger("botocore").setLevel(logging.WARNING)
logger = logging.getLogger('allow-block-importer')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
# handler = logging.handlers.SysLogHandler('/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
handler.formatter = formatter
logger.addHandler(handler)

ACCOUNT = 'dev'

if ACCOUNT != 'sandbox':
  def get_passphrase():
    s3 = boto3.client('s3')
    passphrase = s3.get_object(Bucket=CONNECTIONS_BUCKET, Key=MAIL_PIC_API_AUTH)
    return base64.b64encode('mail:' + passphrase['Body'].read())

  auth = get_passphrase()

  HEADERS = {
    'Authorization': 'Basic ' + auth
  }
  PIC_XGEMAIL_API_URL = 'https://%s/mail/api/xgemail' % (PIC_FQDN)
else:
  HEADERS = {
    'Authorization': 'Basic'
  }
  PIC_XGEMAIL_API_URL = 'http://%s/mail-services/api/xgemail' % (PIC_FQDN)

IMPORTER_URL = PIC_XGEMAIL_API_URL + '/allow-block/import'

logger.info('Allow/Block Importer URL: <%s>', IMPORTER_URL)

files = {'file': open('/tmp/example.csv', 'rb')}
params = {
  'customerId': '84e61a73-5e3b-4616-8719-6098a0cb0ede',
  'replace': True
}

response = requests.post(
    IMPORTER_URL,
    files = files,
    params = params,
    headers=HEADERS,
    timeout=MAIL_PIC_RESPONSE_TIMEOUT
)
response.raise_for_status()
