#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
Print variable assignments where each variable is assigned
the an output value from a CloudFormation stack.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import collections
import re


Assignment = collections.namedtuple(
        "Assignment", ["target", "stack", "output"])


def parse_command_line():
    import optparse

    parser = optparse.OptionParser(
            usage="%prog REGION VAR=STACK.OUTPUT [...]")

    options, args = parser.parse_args()

    if len(args) < 2:
        parser.error("too few arguments")

    region = args[0]

    assignments = []
    for arg in args[1:]:
        m = re.match(r"^(\w+)=([-\w]+)\.(\w+)$", arg)
        if not m:
            parser.error("invalid assignment syntax: %s" % arg)
        target = m.group(1)
        stack  = m.group(2)
        output = m.group(3)
        assignments.append(Assignment(target, stack, output))

    return region, assignments


def print_assignments(region, assignments):
    import boto3

    cf_client = boto3.client("cloudformation", region_name=region)

    assignments_by_stack = collections.defaultdict(list)
    for assignment in assignments:
        assignments_by_stack[assignment.stack].append(assignment)

    for stack, stack_assignments in assignments_by_stack.items():
        response = cf_client.describe_stacks(StackName=stack)

        outputs = {}
        output_items = response["Stacks"][0].get("Outputs", [])
        for output_item in output_items:
            output_key = output_item["OutputKey"]
            output_value = output_item["OutputValue"]
            outputs[output_key] = output_value

        for stack_assignment in stack_assignments:
            print "%s=%s" % (stack_assignment.target, outputs[stack_assignment.output])


def main():
    region, assignments = parse_command_line()
    print_assignments(region, assignments)


if __name__ == "__main__":
    main()
