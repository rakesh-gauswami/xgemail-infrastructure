#!/usr/bin/env
import sys
import argparse
import boto3

sys.path.append("/opt/sophos/xgemail/utils")


def print_record(record):
    print "Email/domain: %s" % record['Item']["key"]
    print "Risk Count  : %s" % record['Item']["risk_count"]


def update_record(updated_risk_value, type_of_record, domain_or_email):
    table.update_item(
        Key={
            'key': domainOrEmail,
        },
        UpdateExpression='SET risk_count = :val1, addressType = :val2',
        ExpressionAttributeValues={
            ':val1': updated_risk_value,
            ':val2': type_of_record
        }
    )
    update_response = table.get_item(
        Key={
            'key': domain_or_email,
        }
    )
    return update_response


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Delivery director config updater')
    parser.add_argument('command', metavar='command', choices=["GET", "DELETE", "ADD", "REDUCE"],
                        help='Type of action/operation')
    parser.add_argument('domainOrEmail', type=str, metavar='domainOrEmail', help='Domain name or email address ')
    parser.add_argument('--region', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'],
                        help = 'the region in which this script runs', required = True)
    parser.add_argument('--risk_value', type=int, metavar='risk_value', choices=xrange(1, 101),
                        help="Risk value to add or reduce. Any value between 1 to 100")
    parser.add_argument("--record_type", type=str, metavar='record_type', choices=["domain", "email"],
                        help='Type of record email/domain')
    args = parser.parse_args()

    if (args.command == "ADD" or args.command == "REDUCE") and (args.risk_value is None or args.record_type is None):
        parser.error("--risk_value and --record_type are required attribute for ADD/REDUCE operation")

    command = args.command
    domainOrEmail = str(args.domainOrEmail).strip()
    riskValue = args.risk_value
    typeOfRecord = args.record_type

    dynamoDb = boto3.resource('dynamodb', args.region)
    table = dynamoDb.Table('tf-delivery-director')

    if command == "GET":
        try:
            response = table.get_item(
                Key={
                    'key': domainOrEmail,
                }
            )
            print_record(response)
        except KeyError:
            print("No record found for given domain/email.")

    if command == "DELETE":
        confirmation = raw_input("Are you sure you want to delete record[Y/N]?")
        if confirmation == 'Y':
            table.delete_item(
                Key={
                    'key': domainOrEmail
                }
            )
            print("Record deleted.")

    if command == "ADD":
        try:
            response = table.get_item(
                Key={
                    'key': domainOrEmail,
                }
            )
            currentRiskValue = int(response['Item']["risk_count"])
            updatedRiskValue = currentRiskValue + int(riskValue)
        except KeyError:
            updatedRiskValue = riskValue
            print("Existing record of given domain/email not found. Adding new record")

        print("Added/Updated Record:")
        print_record(update_record(updatedRiskValue, typeOfRecord, domainOrEmail))

    if command == "REDUCE":
        try:
            response = table.get_item(
                Key={
                    'key': domainOrEmail,
                }
            )
            currentRiskValue = int(response['Item']["risk_count"])
            updatedRiskValue = currentRiskValue - riskValue
        except KeyError:
            print("Existing record of given domain/email not found. Ignoring this request")
            sys.exit(1)

        if updatedRiskValue < 0:
            updatedRiskValue = 0
        print("Updated Record:")
        print_record(update_record(updatedRiskValue, typeOfRecord, domainOrEmail))