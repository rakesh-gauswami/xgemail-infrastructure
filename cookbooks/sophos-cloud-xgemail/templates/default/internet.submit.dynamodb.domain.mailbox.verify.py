import sys
sys.path.append("<%= @xgemail_utils_path %>")
import boto3
import json
import subprocess

AWS_REGION = "<%= @aws_region %>"
ACCOUNT = "<%= @account %>"

POSTFIX_INSTANCE_NAME = '<%= @postfix_instance_name %>'
RELAY_DOMAINS_FILENAME = '<%= @relay_domains_filename %>'
RECIPIENT_ACCESS_FILENAME = '<%= @recipient_access_filename %>'

# Legacy session
session = boto3.session.Session(region_name=AWS_REGION)
dynamoDb = session.resource('dynamodb')
domaintable = dynamoDb.Table('tf-msg-domains')
mailboxtable = dynamoDb.Table('tf-msg-mailboxes')


POSTFIX_CONFIG_DIR = subprocess.check_output(
    [
      'postmulti', '-i', POSTFIX_INSTANCE_NAME, '-x',
      'postconf','-h','config_directory'
    ]
  ).rstrip()

RELAY_DOMAINS_FILE = POSTFIX_CONFIG_DIR + '/' + RELAY_DOMAINS_FILENAME
RECIPIENT_ACCESS_FILE = POSTFIX_CONFIG_DIR + '/' + RECIPIENT_ACCESS_FILENAME

with open(RELAY_DOMAINS_FILE, 'r') as f:
    for domainLine in f:
        domain= domainLine.strip().split(' ', 1)[0]
        #print("checking domain in daynamo:"+domain)
        try:
            response = domaintable.get_item(
                Key={
                    'd_name': domain,
                }
            )
            if not  response['Item']:
                print("Domain not found"+domain)
        except KeyError:
            print("No record found for given domain:"+domain)

with open(RECIPIENT_ACCESS_FILE, 'r') as f:
    for recipientLine in f:
        recipient= recipientLine.strip().split(' ', 1)[0]
        print("checking recipient in daynamo:"+recipient)
        try:
            response = mailboxtable.get_item(
                Key={
                    'mailbox': recipient,
                }
            )
            if not  response['Item']:
                print("Mailbox not found"+recipient)
        except KeyError:
            print("No record found for given email:"+recipient)
