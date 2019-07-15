#!/usr/bin/python
# Copyright: Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function

__metaclass__ = type

ANSIBLE_METADATA = {
    "metadata_version": "1.1",
    "status": ["preview"],
    "supported_by": "community",
}

DOCUMENTATION = """
---
module: ec2_spot_pricing_history_facts
short_description: Gather facts about ec2 spot pricing history in AWS
description:
  - Gather historical facts on the spot prices of different instance types
version_added: "2.4"
requirements:
    - boto3
options:
  region:
    description:
      - The region to use.
    required: true
  availability_zone:
    description:
      - >
        availability zone for which prices should be returned. Returns prices
        for all availability zones by default.
    default: ""
  instance_types:
    description:
      - the types of instances (for example, m3.medium),
        see U(https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html).
        Returns prices for all instance types by default.
    default: ""
  product_descriptions:
    description:
      - the product description for the Spot price. Returns prices for all
        product descriptions by default.
    choices:
      - 'Linux/UNIX'
      - 'SUSE Linux'
      - 'Windows'
      - 'Linux/UNIX (Amazon VPC)'
      - 'SUSE Linux (Amazon VPC)'
      - 'Windows (Amazon VPC)'
    default: []
  start_time:
    description:
      - >
        the date and time, up to the past 90 days, from which to start
        retrieving the price history data. Defaults to the time right now.
    default: "now"
  end_time:
    description:
      - >
        the date and time, up to the current date, from which to stop retrieving
        the price history data. Defaults to the time right now.
    default: "now"
  max_results:
    description:
      - the total number of items to return in the output.
    default: 1000
  filters:
    description:
      - One or more filters
    default: []
extends_documentation_fragment:
    - aws
    - ec2
"""

EXAMPLES = """
# Find the most recent spot price for t3.medium in eu-west-1a.
# Facts are published as `ec2_spot_pricing_history`
- ec2_spot_pricing_history_facts:
    instance_types: ["t3.medium"]
    availability_zone: "eu-west-1a"
    product_descriptions: ["Linux/UNIX"]
    max_results: 1
  register: spot_prices
# Create an instance using the spot price
- ec2:
    spot_price: "{{ ec2_spot_pricing_history[0].spot_price }}"
    vpc_subnet_id: "subnet-07b18fbad727f2444"
    image: "ami-00035f41c82244dab"
    instance_types: "t3.medium"
    group: "my-security-group"
    wait: true
    instance_tags:
      Name: "my spot instance"
# Get the spot prices between a week ago and now
- set_fact:
    one_week_ago: >-
      {{ "%Y-%m-%dT%H:%M:%SZ" | strftime((ansible_date_time.epoch | int ) - (86400 * 7 ) }}
- ec2_spot_pricing_history_facts:
    availability_zone: "eu-west-1a"
    instance_types: ["t3.small"]
    product_descriptions: ["Linux/UNIX"]
    start_time: "{{ one_week_ago }}"
    end_time: "{{ ansible_date_time.iso8601 }}"
"""

RETURN = """
---
ec2_spot_pricing_history:
  description: the spot pricing history
  returned: success
  type: list
  sample: [
    {
      "availability_zone": "eu-west-1a",
      "spot_price": 0.71,
      "instance_types": "t3.medium",
      "product_description": "Linux/UNIX",
      "timestamp": "2019-02-12T13:47:13+00:00"
    }
  ]
"""

import datetime

from ansible.module_utils.basic import AnsibleModule
#from ansible.module_utils.aws.core import AnsibleAWSModule
from ansible.module_utils.ec2 import (
    boto3_conn,
    ec2_argument_spec,
    get_aws_connection_info,
    camel_dict_to_snake_dict,
)
from botocore.exceptions import BotoCoreError, ClientError


def parse_date(module, key):
    value = module.params[key]
    if value == "now":
        return datetime.datetime.now()
    try:
        return datetime.datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")
    except ValueError:
        msg = ("{key}={value} is not a valid date. Dates must be specified in " +
               "ISO8601 format")
        module.fail_json(
            msg=msg.format(key=key, value=value)
        )


def main():
    argument_spec = ec2_argument_spec()
    argument_spec.update(
        dict(
            region=dict(type="str", default="us-west-2"),
            availability_zone=dict(type="str", default=""),
            product_descriptions=dict(
                type="list",
                default=[]
            ),
            instance_types=dict(type="list", default=[]),
            filters=dict(type="list", default=[]),
            start_time=dict(type="str", default="now"),
            end_time=dict(type="str", default="now"),
            max_results=dict(type="int", default=1000),
        )
    )

    module = AnsibleModule(argument_spec=argument_spec)

    #ec2_client = module.client('ec2')
    region, ec2_url, aws_connect_params = get_aws_connection_info(module, boto3=True)
    ec2_client = boto3_conn(module, conn_type='client', resource='ec2', region=region, endpoint=ec2_url,
                     **aws_connect_params)

    start_time = parse_date(module, "start_time")
    end_time = parse_date(module, "end_time")

    try:
        spot_price_history_response = ec2_client.describe_spot_price_history(
            AvailabilityZone=module.params.get("availability_zone"),
            ProductDescriptions=module.params.get("product_descriptions"),
            InstanceTypes=module.params.get("instance_types"),
            Filters=module.params.get("filters"),
            StartTime=start_time,
            EndTime=end_time,
            MaxResults=module.params.get("max_results"),
        )
    except ClientError as ce:
        module.fail_json(msg=ce.message)
    except BotoCoreError as be:
        module.fail_json(msg=be.message)

    snaked_history = []
    for spot_price_history in spot_price_history_response["SpotPriceHistory"]:
        snaked = camel_dict_to_snake_dict(spot_price_history)
        snaked["spot_price"] = float(snaked["spot_price"])
        snaked_history.append(snaked)

    result = dict(ec2_spot_pricing_history=snaked_history)
    module.exit_json(**result)


if __name__ == "__main__":
    main()