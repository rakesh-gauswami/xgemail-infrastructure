#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
AMI Bakery support code.
"""

# TODO ;;; Consider exposing all the logs via Bamboo artifacts.

# TODO ;;; Other issues
#   Create base AMI takes time to install chef, etc.
#   Need newboo to have some extra capacity and not scale in so aggressively.
#   m3.xlarge costs $200/month so we should invest in extra capacity to reduce latency.

import ConfigParser
import collections
import datetime
import logging
import os
import re
import subprocess
import sys
import traceback

try:
    import simplejson as json
except ImportError:
    import json

import boto3
import boto3.s3.transfer

import sophos.amis
import sophos.aws
import sophos.common


# Be sure to use the correct packer executable.
# /usr/bin/packer is the one we want.
# /usr/sbin/packer is a symbolic link to cracklib-packer.
PACKER = "/usr/bin/packer"


class BakeryException(Exception):
    pass


class BakeryClient(object):
    """
    AMI Bakery client for a baking single AMI in a single region.
    """

    def __init__(self, session, region, request_queue_name, response_queue_name):
        """
        Initialize AMI Bakery client object.

        ``session`` is a boto3 Session object.

        ``region`` is the region this client wants to build an AMI in.

        ``request_queue_name`` is the name of the common AMI Bakery request
        queue for ``region``.

        ``response_queue_name`` is the name of the dedicated response queue
        for the current request.
        """

        self.region = region

        self.aws = sophos.aws.AwsHelper(session=session, region=region)

        self.request_queue_name = request_queue_name

        self.request_queue_url = None

        self.response_queue_name = response_queue_name

        self.response_queue_url = None

    def create_request_queue(self):
        """
        Create or lookup the request queue, which probably already exists.
        """

        response = self.aws.sqs_create_queue(QueueName=self.request_queue_name)

        self.request_queue_url = response["QueueUrl"]

    def create_response_queue(self):
        """
        Create the response queue, which shouldn't exist if we name it right.
        """

        response = self.aws.sqs_create_queue(QueueName=self.response_queue_name)

        self.response_queue_url = response["QueueUrl"]

    def send_request(self, ami_bakery_request):
        """
        Send a new request to the request queue.
        """

        request = {
            "bakery": ami_bakery_request,
            "response_queue_url": self.response_queue_url,
        }

        self.aws.sqs_send_message(
                QueueUrl=self.request_queue_url,
                MessageBody=json.dumps(request, ensure_ascii=True))

    def receive_response(self, wait_seconds):
        """
        Return a list of messages from the response queue.
        Wait up to ``wait_seconds`` for messages to appear.
        This method may return multiple messages or None.
        Messages are not guaranteed to be returned in chronological order.
        """

        response = self.aws.sqs_receive_message(
                QueueUrl=self.response_queue_url,
                WaitTimeSeconds=wait_seconds)

        messages = response.get("Messages")

        if messages is None:
            return []

        for message in messages:
            self.aws.sqs_delete_message(
                    QueueUrl=self.response_queue_url,
                    ReceiptHandle=message["ReceiptHandle"])

        return messages

    def delete_response_queue(self):
        if self.response_queue_url is not None:
            self.aws.sqs_delete_queue(QueueUrl=self.response_queue_url)


class BakeryResponseHeader(object):
    """
    Object responsible for sending messages with sequence numbers.
    """

    def __init__(self, aws):
        self.aws = aws
        self.response_queue_url = None
        self.last_sequence_number = 0

    def set_response_queue_url(self, url):
        self.response_queue_url = url

    def send(self, category, summary, data=None, finished=False):
        if self.response_queue_url is None:
            return

        self.last_sequence_number += 1

        body = {
            "baker_instance": self.aws.instance_id(),
            "baker_region": self.aws.region(),
            "category": category,
            "description": summary,
            "finished": finished,
            "sequence": self.last_sequence_number,
            "xdata": data,
        }

        logging.info("sending response %d %s %s", body["sequence"], category, summary)

        self.aws.sqs_send_message(
                QueueUrl=self.response_queue_url,
                MessageBody=json.dumps(body, ensure_ascii=True))


class BakeryResult(object):
    """
    AMI Bakery client results from a single request.
    """

    def __init__(self):
        self.finished = False
        self.messages = []
        self.sequence_number_set = set()

    def record_message(self, sqs_message):
        try:
            body = json.loads(sqs_message["Body"])

            print "RESPONSE MESSAGE:"
            for line in sophos.common.pretty_json_dumps(body).splitlines():
                print line.rstrip()

            sys.stdout.flush()

            if body.get("finished", False):
                self.finished = True

            self.messages.append(body)

            self.sequence_number_set.add(body["sequence"])

        except Exception as e:
            print >> sys.stderr, "Exception processing message body:", e

    def is_complete(self):
        # If we haven't seen a message with finished set then we're not complete.

        if not self.finished:
            return False

        # If there are any gaps in the message sequence then we're not complete.
        # Remember, message sequence numbers start at 1.

        sequence_numbers = sorted(self.sequence_number_set)

        if len(sequence_numbers) == 0:
            return False

        if sequence_numbers[0] != 1:
            return False

        if sequence_numbers[-1] != len(sequence_numbers):
            return False

        # Otherwise we ARE complete.

        return True


class Baker(object):
    """
    Class responsible for handling individual baking requests.
    """

    def __init__(self):
        self.aws = sophos.aws.AwsHelper()

        self.process_config()

    def process_config(self):
        """
        Process initial or updated configuration.
        """

        confobj = ConfigParser.RawConfigParser()
        confobj.read("/opt/sophos/bakery.ini")

        self.request_queue_url = confobj.get("DEFAULT", "request_queue_url")

        # TODO: Make these configurable too?
        self.wait_timeout_seconds = 5
        self.visibility_timeout_seconds = 30
        self.min_available_seconds = 300
        self.data_dir = "/data/bakery"

        if not os.path.isdir(self.data_dir):
            subprocess.check_call(["mkdir", "-p", self.data_dir])

    def receive_message(self):
        """
        Receive 0 or 1 messages from the request queue.
        """

        response = self.aws.sqs_receive_message(
                QueueUrl=self.request_queue_url,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=self.wait_timeout_seconds,
                VisibilityTimeout=self.visibility_timeout_seconds)

        messages = response.get("Messages", [])

        if len(messages) == 0:
            return None

        return messages[0]

    def upload_log_file(self, request, path):
        """
        Upload ``path`` to S3 log files location specified in ``request``.
        """

        bucket = request["bakery"]["LogFilesBucket"]
        prefix = request["bakery"]["LogFilesDir"]
        region = self.aws.get_bucket_location(bucket)
        client = self.aws.new_client("s3", region=region)

        extra_args = {}
        extra_args["SSEKMSKeyId"] = request["bakery"]["LogFilesKmsAlias"]
        extra_args["ServerSideEncryption"] = "aws:kms"

        transfer = boto3.s3.transfer.S3Transfer(client)
        transfer.upload_file(
                path,
                bucket,
                re.sub("/+", "/", prefix + path),
                extra_args=extra_args)

    def create_packer_template(self, request, image_data):
        """
        Create and return dict used to drive packer build command.

        Packer template documentation can be found here:

        https://www.packer.io/docs/templates/introduction.html
        """

        source_ami              = image_data["ImageId"]
        source_name             = image_data.get("Name", "None")
        source_description      = image_data.get("Description", "None")
        source_owner_id         = image_data.get("OwnerId", "None")
        source_owner_alias      = image_data.get("ImageOwnerAlias", "None")
        source_creation_date    = image_data.get("CreationDate", "None")

        tags            = request["bakery"]["ChildTags"]
        volume_size_gb  = request["bakery"]["ChildVolumeSizeGb"]
        name            = tags["Name"]
        branch          = tags["Branch"]
        build           = tags["BuildNumber"]
        account_ids     = request["bakery"]["ChildAccountIds"]
        result_key      = request["bakery"]["ResultKey"]

        bootstrap_commands              = request["bakery"]["BootstrapCommands"]
        bootstrap_environment           = request["bakery"]["BootstrapEnvironment"]
        bootstrap_files_bucket          = request["bakery"]["BootstrapFilesBucket"]
        bootstrap_files_dir             = request["bakery"]["BootstrapFilesDir"]
        bootstrap_files_bucket_region   = self.aws.get_bucket_location(bootstrap_files_bucket)
        bootstrap_files_url             = "s3://%s/%s" % (bootstrap_files_bucket, bootstrap_files_dir)

        bootstrap_dir_path = "/tmp/bootstrap-%s.d" % result_key
        bootstrap_script_path = "bootstrap-%s.sh" % result_key

        log_files_bucket        = request["bakery"]["LogFilesBucket"]
        log_files_dir           = request["bakery"]["LogFilesDir"]
        log_files_file_name     = request["bakery"]["LogFilesFileName"]
        log_files_base_name     = os.path.splitext(os.path.basename(log_files_file_name))[0]
        log_files_kms_alias     = request["bakery"]["LogFilesKmsAlias"]
        log_files_to_get        = request["bakery"]["LogFilesToGet"]
        log_files_bucket_region = self.aws.get_bucket_location(log_files_bucket)
        log_files_file_url      = "s3://%s/%s%s" % (log_files_bucket, log_files_dir, log_files_file_name)

        # We need the KMS key from the same region as the bucket,
        # NOT the region we are running in.
        log_files_aws = sophos.aws.AwsHelper(region=log_files_bucket_region)
        kms_key_id = log_files_aws.get_kms_key_id(log_files_kms_alias)
        assert kms_key_id is not None, "No KMS key id found for %s" % log_files_kms_alias

        with open(bootstrap_script_path, "w") as fp:
            # Fail fast.
            print >> fp, "set -o errexit"
            print >> fp, "set -o nounset"
            print >> fp

            # Configure AWS.
            print >> fp, "/usr/bin/aws configure set default.s3.signature_version s3v4"
            print >> fp, "/usr/bin/aws configure set preview.sdb true"
            print >> fp

            # Upload required logs to S3 when the baking is done.
            print >> fp, "upload_logs() {"
            print >> fp, "    DIR=`mktemp -d`"
            print >> fp, "    mkdir -p $DIR/%s" % log_files_base_name
            print >> fp, "    for dirname in `ls -1 /`; do"
            print >> fp, "        ln -s /$dirname $DIR/%s" % log_files_base_name
            print >> fp, "    done"
            print >> fp, "    cd $DIR"
            for log_file in log_files_to_get:
                log_path = "%s/%s" % (log_files_base_name, log_file)
                log_path = re.sub("/+", "/", log_path)
                print >> fp, "    test -e %s && zip -r %s %s" % (log_path, log_files_file_name, log_path)
            print >> fp, "    /usr/bin/aws --region %s s3 cp %s %s --sse aws:kms --sse-kms-key-id %s" % (
                    log_files_bucket_region,
                    log_files_file_name,
                    log_files_file_url,
                    kms_key_id)
            print >> fp, "    cd /"
            print >> fp, "    /bin/rm -rf $DIR"
            print >> fp, "}"
            print >> fp

            # Add exit-handler to ensure upload happens.
            print >> fp, "on_exit() {"
            print >> fp, "    EXIT_CODE=$?"
            print >> fp, "    upload_logs",
            print >> fp, "    exit ${EXIT_CODE}"
            print >> fp, "}"
            print >> fp, "trap on_exit EXIT"
            print >> fp

            # Resize partition and file system to use entire disk.
            if volume_size_gb > 0:
                # TODO: Discover disk and partition paths by inspection.
                print >> fp, "DISK=/dev/xvdf"
                print >> fp, "PART=/dev/xvdf1"
                # Move backup GPT header to end of the disk.
                print >> fp, "sgdisk -e $DISK"
                # Get last sector.
                print >> fp, "ENDSECTOR=$(sgdisk -E $DISK)"
                # Delete current partition.
                print >> fp, "sgdisk -d 1 $DISK"
                # Replace with new partition.
                print >> fp, "sgdisk -n 1:4096:$ENDSECTOR -c 1:Linux -t 1:8300 $DISK"
                # Re-read the partition table entries.
                print >> fp, "partx -u $DISK"
                # Resize the partition.
                print >> fp, "resize2fs $PART"

            # Record AMI lineage.
            print >> fp, "cat <<EOF >>/etc/ami-lineage.log"
            print >> fp, "ImageId:", source_ami
            print >> fp, "- Name:", source_name
            print >> fp, "- Description:", source_description
            print >> fp, "- OwnerId:", source_owner_id
            print >> fp, "- OwnerAlias:", source_owner_alias
            print >> fp, "- CreationDate:", source_creation_date
            print >> fp, "EOF"

            # Work in a dedicated directory.
            print >> fp, "/bin/mkdir -p %s" % bootstrap_dir_path
            print >> fp, "cd %s" % bootstrap_dir_path
            print >> fp

            # Download bootstrap files.
            print >> fp, "/usr/bin/aws --region %s s3 cp %s . --recursive" % (
                    bootstrap_files_bucket_region, bootstrap_files_url)
            print >> fp

            # Execute bootstrap commands.
            for command in bootstrap_commands:
                print >> fp, command

        # Set environment variables.
        # TODO: Figure out if we need any special quoting or not.
        environment_vars = [ "%s=%s" % (k, v) for k, v in sorted(bootstrap_environment.items()) ]

        packer_template = {
            "builders": [
                {
                    "type": "amazon-chroot",
                    "source_ami": source_ami,
                    "ami_name": "@".join([name, branch, build]),
                    "ami_virtualization_type": "hvm",
                    "ami_users": account_ids,
                    "copy_files": ["/etc/resolv.conf"],
                    "root_volume_size": volume_size_gb,
                    "tags": tags
                }
            ],
            "provisioners": [
                {
                    "type": "shell",
                    "script": bootstrap_script_path,
                    "environment_vars": environment_vars
                },
                {
                    "type": "shell",
                    "inline": ["rm -rf %s" % bootstrap_dir_path]
                }
            ]
        }

        return packer_template

    def parse_packer_output_line(self, line):
        """
        Parse a single line of machine-readable packer output.
        Return a (timestamp, key, data) tuple.
        """

        # Packer log output consists of comma-separated fields.
        # The first three fields are timestamp, target, and category.
        # The remaining data fields depend on the category.
        #
        # Some examples:
        # 1469940520,,ui,say,amazon-chroot output will be in this color.
        # 1469940520,,ui,say,
        # 1469940520,,ui,say,==> amazon-chroot: Prevalidating AMI Name...
        # 1469940533,,ui,message,    amazon-chroot: Mounting: /proc
        # 1469940573,,ui,message,    amazon-chroot: Loaded plugins: priorities%!(PACKER_COMMA) update-motd%!(PACKER_COMMA) upgrade-helper
        # 1469941062,,ui,say,==> amazon-chroot: Deleting the created EBS volume...
        # 1469941062,,ui,say,Build 'amazon-chroot' finished.
        # 1469941062,,ui,say,\n==> Builds finished. The artifacts of successful builds are:
        # 1469941062,amazon-chroot,artifact-count,1
        # 1469941062,amazon-chroot,artifact,0,builder-id,mitchellh.amazon.chroot
        # 1469941062,amazon-chroot,artifact,0,id,us-east-1:ami-9640d681
        # 1469941062,amazon-chroot,artifact,0,string,AMIs were created:\n\nus-east-1: ami-9640d681
        # 1469941062,amazon-chroot,artifact,0,files-count,0
        # 1469941062,amazon-chroot,artifact,0,end
        # 1469941062,,ui,say,--> amazon-chroot: AMIs were created:\n\nus-east-1: ami-9640d681

        fields = line.rstrip().split(",")

        timestamp, target, category = fields[0:3]
        data = fields[3:]

        if category == "ui":
            category = "%s.%s" % (category, data.pop(0))

        key = category if target == "" else "%s.%s" % (target, category)

        # Embedded commas, newlines, and carriage-returns are replaced
        # with "%!(PACKER_COMMA)", "\\n", and "\\r" respectively.
        # We'll just undo the comma substitutions.
        for i, value in enumerate(data):
            data[i] = re.sub("%!(PACKER_COMMA)", ",", value)

        return (timestamp, key, data)

    def parse_packer_output(self, packer_output):
        """
        Parse machine-readable packer output returning a dict mapping
        message type to a list of (timestamp, data-list) tuples.
        """

        entries_by_key = collections.defaultdict(list)

        for line in packer_output.splitlines():
            timestamp, key, data = self.parse_packer_output_line(line)
            entries_by_key[key].append((timestamp, data))

        return entries_by_key

    def log_packer_output(self, packer_output, response_sender):
        """
        Parse packer build command output and generate relevant log messages.
        """

        entries_by_key = self.parse_packer_output(packer_output)

        for key in sorted(entries_by_key.keys()):
            # The number of ui.message log lines is unbounded and can easily
            # exceed the 256K SQS message body size limit.  The data is all
            # in S3 anyway so we are going to skip sending this as a direct
            # message to Bamboo.
            if key == "ui.message":
                continue

            tuples = entries_by_key[key]

            data = []
            for timestamp_str, field_list in tuples:
                timestamp_utc = datetime.datetime.utcfromtimestamp(float(timestamp_str)).strftime("%FT%TZ")
                data.append(" ".join([timestamp_utc] + field_list))

            response_sender.send("LOG", "packer output for key %s" % key, data=data)

        artifact_tuples = entries_by_key.get("amazon-chroot.artifact", [])
        for timestamp, data in artifact_tuples:
            if data[0] == "0" and data[1] == "id":
                region, ami_id = data[2].split(":")
                logging.info("packer created AMI: %s", ami_id)
                response_sender.send("AMI", "ami", data=ami_id)

    def process_message(self, message):
        """
        Process a bakery request message read from an SQS queue.
        Send response messages to the queue specified in the message.
        """

        response_sender = BakeryResponseHeader(self.aws)
        try:
            receipt_handle = message["ReceiptHandle"]
            try:
                body = message["Body"]
                request = json.loads(body)

                # Extract result key, so we can name the working directory.
                result_key = request["bakery"]["ResultKey"]
                work_dir = os.path.join(self.data_dir, result_key)
                subprocess.check_call(["mkdir", "-p", work_dir])
                with sophos.common.cd(work_dir):
                    # Save request.
                    with open("request.json", "w") as fp:
                        print >> fp, sophos.common.pretty_json_dumps(request)
                    self.upload_log_file(request, "request.json")

                    # Extract response queue URL from request.
                    response_queue_url = request["response_queue_url"]
                    response_sender.set_response_queue_url(response_queue_url)
                    response_sender.send("ACK", "received request", data=request)

                    # Make sure we have enough time to process the request.
                    request_time_utc = int(request["bakery"]["RequestTimeUtc"])
                    response_timeout_seconds = int(request["bakery"]["ResponseTimeoutSeconds"])
                    deadline_time_utc = request_time_utc + response_timeout_seconds
                    current_time_utc = int(datetime.datetime.utcnow().strftime("%s"))
                    available_seconds = deadline_time_utc - current_time_utc
                    if available_seconds < self.min_available_seconds:
                        raise BakeryException("Not enough time to process message; only %d seconds available." % available_seconds)

                    # Extend the message visibility timeout to cover the deadline.
                    # This prevents other baker objects from processing the message.
                    self.aws.sqs_change_message_visibility(
                            QueueUrl=self.request_queue_url,
                            ReceiptHandle=receipt_handle,
                            VisibilityTimeout=available_seconds)

                    # Find the parent AMI.
                    image_data, error_message = sophos.amis.find_image_data(
                            request["bakery"]["ParentQueries"], self.aws.client("ec2"))
                    if error_message is not None:
                        raise BakeryException("Parent AMI search failed: %s" % error_message)

                    # Create packer template.
                    packer_template = self.create_packer_template(request, image_data)
                    response_sender.send("LOG", "created packer template", data=packer_template)

                    packer_template_path = "packer-template.json"
                    with open(packer_template_path, "w") as fp:
                        print >> fp, sophos.common.pretty_json_dumps(packer_template)
                    self.upload_log_file(request, packer_template_path)

                    # Verify packer template by inspecting it.
                    rr = sophos.common.run_advanced([PACKER, "inspect", packer_template_path])

                    inspection_report = rr.stdout
                    if inspection_report is not None:
                        packer_inspection_path = "packer-inspection.txt"
                        with open(packer_inspection_path, "w") as fp:
                            fp.write(inspection_report)
                        self.upload_log_file(request, packer_inspection_path)

                    response_sender.send("LOG", "inspected packer template", data=inspection_report)

                    if rr.returncode != 0:
                        raise BakeryException("Packer inspect command failed, rc=%d, stderr=%r" % (rr.returncode, rr.stderr))

                    # Run packer build to create the new AMI.  Use the
                    # -machine-readable option so we can parse packer output
                    # to extract the AMI ID.
                    rr = sophos.common.run_advanced([PACKER, "-machine-readable", "build", packer_template_path])

                    # Write and upload packer output file before sending ANY response messages.
                    # If the packer command took too long the response queue may be deleted,
                    # causing an exception that would bypass any subsequent code.
                    packer_output = rr.stdout
                    if packer_output is not None:
                        packer_output_path = "packer-output.txt"
                        with open(packer_output_path, "w") as fp:
                            fp.write(packer_output)
                        self.upload_log_file(request, packer_output_path)

                    # Now we can send response messages.
                    # SQS has a message body size limit of 262144 bytes (256K).
                    # Packer output may be larger.  User can get details from S3.
                    response_sender.send("LOG", "ran packer", data=None)
                    if packer_output is not None:
                        self.log_packer_output(packer_output, response_sender)

                    if rr.returncode != 0:
                        raise BakeryException("Packer build command failed, rc=%d, stderr=%r" % (rr.returncode, rr.stderr))

            finally:
                try:
                    self.aws.sqs_delete_message(
                            QueueUrl=self.request_queue_url,
                            ReceiptHandle=receipt_handle)
                except Exception as e:
                    data = {
                        "traceback": traceback.format_exc(),
                        "exception": str(e),
                    }
                    response_sender.send("ERR", "exception: %s" % e.message, data=data)

        except Exception as e:
            data = {
                "traceback": traceback.format_exc(),
                "exception": str(e),
            }
            response_sender.send("ERR", "exception: %s" % e.message, data=data)

        finally:
            response_sender.send("END", "finished", finished=True)

    def perform_maintenance(self):
        """
        Perform whatever occasional maintenance is required.
        """

        # Clean data directory.
        with sophos.common.cd(self.data_dir):
            subprocess.call(["find", ".", "-mtime", "+7", "-exec", "rm", "-rf", "{}", ";"])
