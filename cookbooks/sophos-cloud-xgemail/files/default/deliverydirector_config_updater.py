#!/usr/bin/env
import sys
import argparse
import boto3

sys.path.append("/opt/sophos/xgemail/utils")


def print_record(record):
    print"==============================================================================="
    print "Email/domain: %s" % record['Item']["key"]
    print "Risk Count  : %s" % record['Item']["risk_count"]
    print "Delivery Type : %s" % record['Item']["delivery_type"]
    print "Is SubDomain : %s" % record['Item']["is_sub_domain"]
    print"==============================================================================="


def print_all(records):
    print"==============================================================================="
    for record in records['Items']:
        print "Email/domain: %s" % record["key"]
        print "Risk Count  : %s" % record["risk_count"]
        delivery_type = record.get("delivery_type")
        is_sub_domain = record.get("is_sub_domain")
        if delivery_type:
            print "Delivery Type : %s" % delivery_type
        if is_sub_domain:
            print "Is SubDomain : %s" % is_sub_domain
        print"==============================================================================="


def update_record(updated_risk_value,
                  type_of_record,
                  domain_or_email,
                  delivery_type,
                  is_sub_domain):
    table.update_item(
        Key={
            'key': domainOrEmail,
        },
        UpdateExpression='SET risk_count = :val1, addressType = :val2 , delivery_type = :val3 , is_sub_domain = :val4',
        ExpressionAttributeValues={
            ':val1': updated_risk_value,
            ':val2': type_of_record,
            ':val3': delivery_type,
            ':val4': is_sub_domain
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
    parser.add_argument('command', metavar='command choices=[GET, GET_ALL, DELETE, ADD, REDUCE]',
                        choices=["GET", "GET_ALL", "DELETE", "ADD", "REDUCE"],
                        help='Type of action/operation choices=[GET, GET_ALL, DELETE, ADD, REDUCE]')
    parser.add_argument('--domainOrEmail', type=str, metavar='Domain name or email address',
                        help='Domain name or email address ')
    parser.add_argument('--region', choices=['eu-central-1', 'eu-west-1', 'us-west-2', 'us-east-2'],
                        help='the region in which this script runs', required=True)
    parser.add_argument('--risk_value', type=int, metavar='Risk value to add or reduce. Any value between 1 to 100',
                        choices=xrange(1, 101),
                        help="Risk value to add or reduce. Any value between 1 to 100")
    parser.add_argument("--record_type", type=str, metavar='choices=[domain, email]', choices=["domain", "email"],
                        help='Type of record email/domain. choices=[domain, email]')
    parser.add_argument("--delivery_type", type=str, metavar='delivery_type choices=[RISK, BULK, DOMAIN]',
                        choices=["RISK", "BULK", "DOMAIN"],
                        help='Delivery node type to which mails will be routed through  choices=[RISK, BULK, DOMAIN]')
    parser.add_argument("--isSubDomain", type=bool, metavar='isSubDomain', choices=[True, False],
                        help='Match sub domains as well when true')
    args = parser.parse_args()

    if (args.command == "GET" or args.command == "DELETE") and (args.domainOrEmail is None):
        parser.error("--domainOrEmail is required attribute for GET/DELETE operation")

    if (args.command == "ADD" or args.command == "REDUCE") and \
            (args.risk_value is None or args.record_type is None or args.domainOrEmail is None
             or args.delivery_type is None):
        parser.error(
            "--domainOrEmail,--risk_value,--record_type,"
            "--delivery_type are required attribute for ADD/REDUCE operation")

    command = args.command

    if command != "GET_ALL":
        domainOrEmail = str(args.domainOrEmail).strip()
        riskValue = args.risk_value
        typeOfRecord = args.record_type
        deliveryType = args.delivery_type

        if args.isSubDomain is None:
            # isSubDomain Default True
            isSubDomain = True
        else:
            isSubDomain = args.isSubDomain

    dynamoDb = boto3.resource('dynamodb', args.region)
    table = dynamoDb.Table('tf-delivery-director')

    if command == "GET_ALL":
        response = table.scan()
        if len(response) == 0:
            print "No record found in this region"
        else:
            print_all(response)

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
        print_record(update_record(updatedRiskValue, typeOfRecord, domainOrEmail, deliveryType, isSubDomain))

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
        print_record(update_record(updatedRiskValue, typeOfRecord, domainOrEmail, deliveryType, isSubDomain))
