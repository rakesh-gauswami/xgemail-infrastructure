#!/usr/bin/env
import argparse
import sys
import boto3

dynamoDb = boto3.resource('dynamodb')
table = dynamoDb.Table('delivery_director')


def print_record(record):
    print "Email/domain: %s" % record['Item']["key"]
    print "Risk Count  : %s" % record['Item']["risk_count"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Delivery director config updater')
    parser.add_argument('command', metavar='command', choices=["GET", "DELETE", "ADD", "REDUCE"],
                        help='Type of action/operation')
    parser.add_argument('domainOrEmail', metavar='domainOrEmail', help='Domain name or email address ')
    parser.add_argument('--risk_value', metavar='risk_value',
                        help="Risk value to add or reduce. Any value between 1 to 100")
    parser.add_argument("--record_type", metavar='record_type', choices=["domain", "email"],
                        help='Type of record email/domain')
    args = parser.parse_args()

    command = args.command
    domainOrEmail = str(args.domainOrEmail).strip()
    rangeForRiskValue = range(1, 100)

    if command == "GET":
        try:
            response = table.get_item(
                Key={
                    'key': domainOrEmail,
                }
            )
            print_record(response)
            sys.exit(0)

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
            sys.exit(0)
    try:
        riskValue = int(args.risk_value)
        if riskValue not in rangeForRiskValue:
            print("Please enter value between 1 to 100 for risk_value.")
            sys.exit(0)
    except ValueError:
        # This block will be executed when non numeric value passed
        print("Please enter value between 1 to 100 for risk_value.")
        sys.exit(0)

    typeOfRecord = args.record_type

    if command == "ADD":
        if riskValue is None or typeOfRecord is None:
            print("--risk_value and --record_type are required attribute for ADD operation")
        else:
            try:
                response = table.get_item(
                    Key={
                        'key': domainOrEmail,
                    }
                )
                currentRiskValue = int(response['Item']["risk_count"])
                updatedRiskValue = currentRiskValue + int(riskValue)
            except KeyError:
                updatedRiskValue = int(riskValue)
                print("Existing record of given domain/email not found. Adding new record")

            table.update_item(
                Key={
                    'key': domainOrEmail,
                },
                UpdateExpression='SET risk_count = :val1, addressType = :val2',
                ExpressionAttributeValues={
                    ':val1': updatedRiskValue,
                    ':val2': typeOfRecord
                }
            )
            response = table.get_item(
                Key={
                    'key': domainOrEmail,
                }
            )
            print("Added Record:")
            print_record(response)

    if command == "REDUCE":
        if riskValue is None:
            print("--risk_value is required attribute for REDUCE operation")
        else:
            try:
                response = table.get_item(
                    Key={
                        'key': domainOrEmail,
                    }
                )
                currentRiskValue = int(response['Item']["risk_count"])
                updatedRiskValue = currentRiskValue - int(riskValue)
            except KeyError:
                print("Existing record of given domain/email not found. Ignoring this request")
                sys.exit(0)

            if updatedRiskValue < 0:
                updatedRiskValue = 0

            table.update_item(
                Key={
                    'key': domainOrEmail,
                },
                UpdateExpression='SET risk_count = :val1, addressType = :val2',
                ExpressionAttributeValues={
                    ':val1': updatedRiskValue,
                    ':val2': typeOfRecord
                }
            )
            response = table.get_item(
                Key={
                    'key': domainOrEmail,
                }
            )
            print("Updated Record:")
            print_record(response)
