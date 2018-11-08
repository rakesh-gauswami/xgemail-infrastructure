#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

__author__ = 'cloud-email-dev@sophos.com'

"""
Properly terminates an Xgemail submit or delivery instance.
This is expected to be run on the instance that should be terminated.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import boto3
import json
import os
import signal
import subprocess
import sys

def main():
    # Restore default handling for SIGPIPE.  Otherwise an exception gets
    # raised when output is piped through another program and the process
    # gets terminated by an interrupt.  See:
    #   https://github.com/vsbuffalo/devnotes/wiki/Python-and-SIGPIPE
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)

    # Suppress stack trace when process is terminated by Ctrl-C.
    try:
        instance_id = run_cmd(
            'curl http://169.254.169.254/latest/meta-data/instance-id'
        )

        document_response = run_cmd(
            'curl http://169.254.169.254/latest/dynamic/instance-identity/document'
        )

        region = json.loads(document_response)['region']

        # some sanity check on instance id
        if not instance_id or not instance_id.startswith('i-'):
            print 'Instance Id <%s> invalid, exiting.' % (instance_id)
            sys.exit(1)

        if is_submit_instance():
            handle_submit_termination(
                instance_id,
                region
            )
        elif is_delivery_instance():
            handle_delivery_termination(
                instance_id,
                region
            )
        else:
            print 'Unable to determine instance type, exiting.'
            sys.exit(1)

        sys.exit(0)
    except KeyboardInterrupt:
        print 'Terminate instance ended manually'
        sys.exit(1)
    except Exception as e:
        print 'Terminate instance ended unexpectedly'
        raise e

# returns true if this is a submit instance
def is_submit_instance():
    return os.path.isdir('/etc/postfix-is')

# returns true if this is a delivery instance
def is_delivery_instance():
    return os.path.isdir('/etc/postfix-cd')

# attempts to terminate a submit instance by performing
# the following steps:
#
# 1. Check the postfix queue. Only continue if queue is empty.
# 2. Delete record from SimpleDB.
# 3. Scale back autoscaling which will also terminate the instance.
#
def handle_submit_termination(instance_id, region):
    print 'Attempting termination of submit node <%s:%s>' % (region, instance_id)

    stop_policy_poller_service()
    check_postfix_queue('postfix-is')
    delete_from_sdb(instance_id, region)
    scale_back_autoscaling_group(instance_id, region)

# attempts to terminate a delivery instance by performing
# the following steps:
#
# 1. Stop the SQS consumer.
# 2. Check the postfix queue. Only continue if queue is empty.
# 3. Delete record from SimpleDB.
# 4. Scale back autoscaling which will also terminate the instance.
#
def handle_delivery_termination(instance_id, region):
    print 'Attempting termination of delivery node <%s>' % (instance_id)

    stop_sqs_consumer()
    check_postfix_queue('postfix-cd')
    delete_from_sdb(instance_id, region)
    scale_back_autoscaling_group(instance_id, region)

# run a provided shell command
def run_cmd(cmd, comment = None):
    if not cmd:
        return

    if comment:
        print comment

    process = subprocess.Popen(
        cmd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    out, err = process.communicate()

    if process.returncode != 0:
        print 'Error while running command <%s>, exiting.' % (cmd)
        sys.exit(process.returncode)

    return out.strip()

# stop SQS consumer (used on delivery instances)
def stop_sqs_consumer():
    response = run_cmd(
        '/sbin/initctl status xgemail-sqs-consumer',
        'Checking SQS consumer status'
    )

    if response == 'xgemail-sqs-consumer stop/waiting':
        print 'SQS consumer already stopped.'
        return

    run_cmd(
        '/sbin/initctl stop xgemail-sqs-consumer',
        'Stopping SQS consumer'
    )

def stop_policy_poller_service():
    response = run_cmd(
        '/sbin/initctl status xgemail-sqs-policy-poller',
        'Checking SQS policy poller status'
    )

    if response == 'xgemail-sqs-policy-poller stop/waiting':
        print 'SQS policy poller already stopped.'
        return

    run_cmd(
        '/sbin/initctl stop xgemail-sqs-policy-poller',
        'Stopping SQS policy poller'
    )

# check the postfix queue. Fail if the queue is not empty.
def check_postfix_queue(queue):
    if not queue:
        print 'No queue provided, exiting.'
        sys.exit(1)

    response = run_cmd(
        '/usr/sbin/postmulti -i %s -x postqueue -p' % (queue),
        'Checking Postfix queues'
    )

    if response != 'Mail queue is empty':
        print 'Mail queue is NOT empty, exiting.'
        sys.exit(1)

# delete the record associated with the given instance id
# from the Simple DB Volume Tracker
def delete_from_sdb(instance_id, region):
    if not instance_id:
        print 'No Instance Id provided, exiting.'
        sys.exit(1)

    if not region:
        print 'No region provided, exiting.'
        sys.exit(1)

    client_ec2 = boto3.client('ec2', region_name = region)
    client_sdb = boto3.client('sdb', region_name = 'us-west-2')

    # we first need to retrieve the VolumeId for the current instance
    instance_response = client_ec2.describe_instance_attribute(
        InstanceId = instance_id,
        Attribute = 'blockDeviceMapping'
    )

    block_device_mappings = instance_response['BlockDeviceMappings']
    volume_id = None
    for block_device in block_device_mappings:
        if block_device['DeviceName'] == '/dev/xvdi':
            volume_id = block_device['Ebs']['VolumeId']
            break

    if not volume_id:
        print 'Unable to retrieve volume_id, exiting.'
        sys.exit(1)

    # find the SDBVolumeTracker domain name
    all_domains = client_sdb.list_domains()
    domain_name = None
    for domain in all_domains['DomainNames']:
        if domain.startswith('SDBVolumeTracker-SimpleDbDomain'):
            domain_name = domain
            break

    if not domain_name:
        print 'Unable to retrieve SDB Volume Tracker domain name, exiting.'
        sys.exit(1)

    # query the SDB Volume Tracker database to find the attribute similar to the following:
    # CloudEmail:xgemail:eu-central-1a:submit-1:submit-1, which is the attribute that will
    # be deleted from the database
    select_query = \
        "select *" \
        "from `{}`" \
        "where itemName() like 'CloudEmail:xgemail:%'".format(domain_name)

    query_response = client_sdb.select(
        SelectExpression = select_query,
        ConsistentRead = True
    )

    attribute_name = None
    for item in query_response['Items']:
        for attribute in item['Attributes']:
            if attribute['Value'] == volume_id:
                attribute_name = item['Name']
                break

    if not attribute_name:
        print 'Unable to retrieve attribute name to be deleted from SDBVolumeTracker, exiting.'
        sys.exit(1)

    print 'Deleting <%s> attribute from DomainName <%s> for instance id <%s>' % \
        (attribute_name, domain_name, instance_id)

    client_sdb.delete_attributes(
        DomainName = domain_name,
        ItemName = attribute_name
    )

    print 'Checking that <%s> has been deleted from SDBVolumeTracker' % (attribute_name)

    verify_query = \
        "select *" \
        "from `{}`" \
        "where itemName() = '{}'".format(domain_name, attribute_name)

    verify_response = client_sdb.select(
        SelectExpression = verify_query,
        ConsistentRead = True
    )

    if 'Items' in verify_response:
        print 'Record <%s> not yet deleted from SDBVolumeTracker' % (attribute_name)
        sys.exit(1)

# scale back the autoscaling group associated to the Instance Id. Since
# each autoscaling group only contains one instance, the instance will
# subsequently be terminated.
def scale_back_autoscaling_group(instance_id, region):
    client_autoscaling = boto3.client('autoscaling', region_name = region)

    describe_response = client_autoscaling.describe_auto_scaling_instances(
        InstanceIds = [instance_id]
    )

    # the way submit and delivery nodes are currently setup, each
    # autoscaling group only contians one instance.
    if len(describe_response['AutoScalingInstances']) <= 0:
        print 'Unable to retrieve autoscaling groups, exiting.'
        sys.exit(1)

    autoscaling_group_name = describe_response['AutoScalingInstances'][0]['AutoScalingGroupName']

    print "Scaling back autoscaling group <%s>. Instance <%s> will be terminated" % \
        (autoscaling_group_name, instance_id)

    client_autoscaling.update_auto_scaling_group(
        AutoScalingGroupName = autoscaling_group_name,
        MinSize = 0,
        DesiredCapacity = 0
    )

if __name__ == "__main__":
    main()
