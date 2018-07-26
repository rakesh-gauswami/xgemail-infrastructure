#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2017, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
This script will be used as a pre-termination step to ensure that no customer email resides on the instances
prior to termination.
It is designed to be used as a standalone script or to be imported and have functions used as a module.
It will be run as a standalone script on our current Xgemail AutoScaling Groups, which consist of a single Instance each.
This script will be used as a module from the SQS LifeCycle Poller as part of the Termination LifeCycle.
In this process the SQS LifeCycle Poller script will use logic similar to the main() function, and call the
functions in this script accordingly.
"""

# TODO: Phase 1 -  This is being setup as standalone for now
#   will be merged with the LifeCycle Poller recipe once
#   the new AutoScaling Groups are in place.

import argparse
import json
import subprocess
import sys
import time
import logging
import logging.handlers
import boto3
import os.path

# logging to syslog setup
logger = logging.getLogger("lifecycle-poller")
logger.setLevel(logging.INFO)
syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
syslog_handler.formatter = formatter
logger.addHandler(syslog_handler)


def send_sns_alert(sns_topic, message):
    """
    Send provided message as an alarm to specified Amazon Web Services SNS Topic.
    """
    if not message:
        logger.info("Function: send_sns_alert - Need a message to send an alert.")
        sys.exit(1)

    document_response = run_cmd(
            ['curl', 'http://169.254.169.254/latest/dynamic/instance-identity/document']
        )
    instance_id = json.loads(document_response)['instanceId']
    region = json.loads(document_response)['region']
    sns = boto3.client('sns', region_name=region)

    response = sns.publish(
        TopicArn=sns_topic,
        Subject="Alarm from EC2 Instance: %s in Region: %s" % (instance_id, region),
        Message=message
    )
    logger.info("SNS MessageId: %s" % response['MessageId'])


def run_cmd(cmd, comment=None):
    """
    Run a provided shell command.
    """
    if not cmd:
        logger.error("Function: run_cmd - Command not provided.")
        sys.exit(1)

    if comment:
        logger.info(comment)

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    out, err = process.communicate()

    if process.returncode != 0:
        logger.error("Error while running command [ %s ], exiting." % cmd)
        sys.exit(process.returncode)

    return out.strip()


def service_controller(service, action):
    """
    Used to control the Xgemail SQS Consumer Service.
    """
    process = subprocess.Popen(
        ('/sbin/service', service, action),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    out, err = process.communicate()
    logger.info(out.strip())

    return process.returncode


def stop_sqs_consumer(sqs_service, alarm):
    """
    Stop SQS consumer (used on delivery instances)
    Returns True if the service is stopped or False if there is a problem
    Does it's best to detect problems and fix them.
    """
    if not sqs_service:
        logger.error("Function: stop_sqs_consumer - sqs_service not provided.")
        sys.exit(1)

    status = service_controller(sqs_service, 'status')
    if status == 0:
        logger.info("Xgemail SQS Consumer Service is running. Stopping Service.")
        if service_controller(sqs_service, 'stop') == 0:
            logger.info("Xgemail SQS Consumer Service is Stopped.")
            return True
    if (status == 1) or (status == 2):
        logger.warning("Xgemail SQS Consumer Service is dead but pid and lock files exist. Forcing a restart then stopping cleanly.")
        if service_controller(sqs_service, 'force-restart') == 0:
            logger.info("Xgemail SQS Consumer Service is Running. Stopping Service")
            if service_controller(sqs_service, 'stop') == 0:
                logger.info("Xgemail SQS Consumer Service is Stopped.")
                return True
    if status == 3:
        logger.info("Xgemail SQS Consumer Service is already Stopped.")
        return True

    error_message = "CRITICAL! Xgemail cannot stop SQS Consumer"
    send_sns_alert(alarm, error_message)
    return False


def check_postfix_queue(queue):
    """
    Check the postfix queue.
    Returns the number of messages in the Postfix queue
    """
    if not queue:
        logger.error("Function: check_postfix_queue - No queue provided.")
        sys.exit(1)

    subdirs = ['maildrop', 'incoming', 'active', 'defer', 'deferred']
    messages = 0

    for q in subdirs:
        # TODO: replace static storage path with new asg volume when XGE-1807 is pulled in
        path = ("/storage/%s/%s" % (queue,q))
        messages += len([f for f in os.listdir(path)if os.path.isfile(os.path.join(path, f))])

    return messages


def is_postfix_queue_drained(queue, count, alarm):
    """
    Keep checking the Postfix queue until it is drained or is unable to be drained.
    """
    if not queue:
        logger.error("Function: is_postfix_queue_drained - 'No queue provided.")
        sys.exit(1)
    if not count:
        logger.error("Function: is_postfix_queue_drained - 'count not provided.")
        sys.exit(1)
    if not alarm:
        logger.error("Function: is_postfix_queue_drained - 'alarm not provided.")
        sys.exit(1)

    queue_count = count
    while queue_count != 0:
        last_count = queue_count
        time.sleep(10)
        queue_count = check_postfix_queue(queue)
        logger.info("Queue Count: %d" % queue_count)
        if queue_count < last_count:
            continue
        if queue_count >= last_count:
            logger.warning("Email queue doesn't seem to be draining. Waiting a full minute before trying again.")
            # Attempt to flush postfix queue then wait for drop
            run_cmd(
                ['/usr/sbin/postmulti', '-i', queue, '-x', 'postqueue', '-f']
            )
            time.sleep(60)
            queue_count = check_postfix_queue(queue)
            if queue_count < last_count:
                logger.info("Email queue is draining. Continuing with regular check.")
                continue
            error_message = "CRITICAL! *** %d *** Undelivered messages are stuck in the email queue." % queue_count
            logger.critical(error_message)
            send_sns_alert(alarm, error_message)
            return False

    return True


def get_postfix_instance():
    """
    Return the Postfix Multi-Instance name.
    """
    output = run_cmd(
        ['postmulti', '-l'],
        'Getting Postfix Instance'
    )
    for line in output.split('\n'):
        if 'mta' in line:
            return line.split()[0]


# Argument Parser
def parse_command_line():
    parser = argparse.ArgumentParser(description="Run before termination to ensure customer email messages are not lost.")
    parser.add_argument("--topic", "-t", dest='alarm_topic_arn', default=False, help="The ARN of the SNS Topic to send Alarm notifications to.")
    parser.add_argument("--service", "-s", dest='service', default='xgemail-sqs-consumer', help="Enter the name of the xgemail-sqs-consumer service.")

    return parser.parse_args()


def main():
    """
    When executed from the command line as a script. If used as a module use similar logic.
    """
    args = parse_command_line()
    logging.info("Starting Xgemail Pre-Termination Process.")
    postfix_instance = get_postfix_instance()
    logger.info("Postfix Instance: %s" % postfix_instance)
    if postfix_instance == 'postfix-cd':
        if stop_sqs_consumer(args.service, args.alarm_topic_arn) is False:
            logger.error("Unable to continue. There is a problem with the Xgemail SQS Consumer Service.")
            sys.exit(1)
    queue_check = check_postfix_queue(postfix_instance)
    logger.info("Messages in Postfix queue: %d" % queue_check)
    if queue_check != 0:
        logger.warning("There are %d email messages still in the queue. We need to wait for them to drain." % queue_check)
        if is_postfix_queue_drained(postfix_instance, queue_check, args.alarm_topic_arn) is True:
            logger.info("The wait is over. The Postfix queue is now empty.")
        else:
            logger.critical("process finished with errors.")
            sys.exit(1)

    logger.info("Xgemail Pre-Termination Process Complete. Instance may now be shutdown/terminated without any loss of email data.")
    sys.exit(0)

if __name__ == "__main__":
    main()