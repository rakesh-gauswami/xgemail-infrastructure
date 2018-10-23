#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#

import json
import logging
import base64
from awshandler import AwsHandler
import policyformatter
from recipientsplitconfig import RecipientSplitConfig
import time
from logging.handlers import SysLogHandler

#Constants
EFS_POLICY_STORAGE_PATH = '/policy-storage/'

MULTI_POLICY_DOMAINS_PATH = 'config/policies/domains/'
EFS_MULTI_POLICY_DOMAINS_PATH = EFS_POLICY_STORAGE_PATH + MULTI_POLICY_DOMAINS_PATH

MULTI_POLICY_ENDPOINTS_PATH = 'config/policies/endpoints/'
EFS_MULTI_POLICY_ENDPOINTS_PATH = EFS_POLICY_STORAGE_PATH + MULTI_POLICY_ENDPOINTS_PATH

INBOUND_RELAY_CONTROL_PATH = EFS_POLICY_STORAGE_PATH + 'config/inbound-relay-control/'
EFS_MULTI_POLICY_CONFIG_PATH = INBOUND_RELAY_CONTROL_PATH + 'multi-policy/'
EFS_MULTI_POLICY_CONFIG_FILE = EFS_MULTI_POLICY_CONFIG_PATH + 'global.CONFIG'
FLAG_TO_READ_POLICY_FROM_S3_FILE = EFS_MULTI_POLICY_CONFIG_PATH + 'msg_producer_read_policy_from_s3_global.CONFIG'
FLAG_TO_TOC_USER_BASED_SPLIT = EFS_MULTI_POLICY_CONFIG_PATH + 'msg_producer_toc_user_based_split_global.CONFIG'
FLAG_TO_SPLIT_BY_RECIPIENTS = INBOUND_RELAY_CONTROL_PATH + 'msg_producer_split_by_recipient.CONFIG'

logger = logging.getLogger('multi-policy-reader-utils')
logger.setLevel(logging.INFO)
syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
formatter = logging.Formatter(
    '[%(name)s] %(process)d %(levelname)s %(message)s'
)
syslog_handler.formatter = formatter
logger.addHandler(syslog_handler)

def split_by_recipient(split_config, recipients, aws_region, policy_bucket_name, read_from_s3):
    """
        Determines if the current message must be split by recipients.
        Returns True if split by recipient required, False otherwise.
    """
    if (len(recipients) <= 1):
        return False

    try:
        # at this point, all recipients belong to the same customer so it is sufficient
        # to retrieve the customer_id from the first recipient in the list
        customer_policy = read_policy(
            recipients[0],
            aws_region,
            policy_bucket_name,
            read_from_s3
        )
        customer_id = customer_policy['customerId']

        return split_config.is_split_by_recipient_enabled(customer_id)
    except:
        logger.error('Unable to split by recipients')
        return False

def build_policy_map(recipients, aws_region = None, policy_bucket_name = None, policies = {}):
    """
        This method builds a map with <policy_id> as key
        and a list of recipient emails that belong to that policy as values.
        Where the flag to read from s3 is set to true and <aws_region> and <policy_bucket_name> parameters are supplied,
        it will read the policy from s3. Otherwise policy will be read locally via mounted storage
    """
    user_list = policies.copy()
    split_config = RecipientSplitConfig(FLAG_TO_SPLIT_BY_RECIPIENTS)

    if split_by_recipient(split_config, recipients, aws_region, policy_bucket_name, read_from_s3):
        for recipient in recipients:
            retrieve_user_id_and_add_to_user_list(customer_policy, user_list, recipient)
        return user_list

    read_from_s3 = get_read_from_s3_enabled()
    user_based_split = get_user_based_split_enabled()
    is_toc_enabled = False
    policy_list = policies.copy()

    if (user_based_split and len(recipients) > 1):
        logger.info("ToC user based split block for recipients [{0}]".format(recipients))

        for recipient in recipients:
            customer_policy = read_policy(recipient, aws_region, policy_bucket_name, read_from_s3)
            if not customer_policy:
                return None

            if (is_toc_enabled != True): #Not to read endpoint policy for ToC config if found enabled for processed recipients
                endpoint_policy = read_policy_endpoint(recipient, customer_policy['userId'], aws_region, policy_bucket_name, read_from_s3)
                if not endpoint_policy:
                    return None
                is_toc_enabled = read_toc_config(recipient, endpoint_policy)

            if (is_toc_enabled != True): #Not to build polcy map if ToC found enabled for processing / processed recipient
                retrieve_policy_id_and_add_to_policy_list(customer_policy, policy_list, recipient) #Required to build policy map as ToC may disbale for all recipients to avoid reiteration
            retrieve_user_id_and_add_to_user_list(customer_policy, user_list, recipient) #user map will have one to one key (userid), value (recipient) mapping

        if (is_toc_enabled == True): # Return user map when ToC found enable.
            logger.info("ToC is enabled so returning user list : [{0}]".format(user_list))
            return user_list

    elif (aws_region and policy_bucket_name and read_from_s3):
        logger.debug("Reading policy for [{0}] directly from s3".format(recipients))
        for recipient in recipients:
            begin_time = time.time()

            customer_policy = read_policy_from_S3(recipient, aws_region, policy_bucket_name)

            elapsed_time = time.time() - begin_time
            elapsed_time = elapsed_time * 1000

            logger.debug("Policy_Read_MSG_PRODUCER result returned in {0} ms".format(elapsed_time))
            if not customer_policy:
                return None

            retrieve_policy_id_and_add_to_policy_list(customer_policy, policy_list, recipient)


    else:
        logger.debug("Reading policy for [{0}] directly from EFS".format(recipients))
        for recipient in recipients:
            begin_time = time.time()

            customer_policy = read_policy_from_EFS(recipient)

            elapsed_time = time.time() - begin_time
            elapsed_time = elapsed_time * 1000

            logger.debug("Policy_Read_MSG_PRODUCER result returned in {0} ms".format(elapsed_time))

            if not customer_policy:
                return None

            retrieve_policy_id_and_add_to_policy_list(customer_policy, policy_list, recipient)

    return policy_list


def read_policy_from_EFS(recipient):
    file_name = build_recipient_file_path(recipient, EFS_MULTI_POLICY_DOMAINS_PATH)
    if not file_name:
        return None

    return load_multi_policy_file_locally(file_name)

def read_endpoint_policy_from_EFS(userid):
    file_name = EFS_MULTI_POLICY_ENDPOINTS_PATH + userid + ".POLICY"
    if not file_name:
        return None

    return load_multi_policy_file_locally(file_name)

def read_policy_from_S3(recipient, aws_region, policy_bucket_name):
    file_name = build_recipient_file_path(recipient, MULTI_POLICY_DOMAINS_PATH)
    if not file_name:
        return None

    return load_multi_policy_file_from_S3(aws_region, policy_bucket_name, file_name)

def read_endpoint_policy_from_S3(userid, aws_region, policy_bucket_name):
    file_name = MULTI_POLICY_ENDPOINTS_PATH + userid + ".POLICY"
    if not file_name:
        return None

    return load_multi_policy_file_from_S3(aws_region, policy_bucket_name, file_name)

def load_multi_policy_file_locally(filename):
    try:
        with open(filename) as filehandle:
            return json.load(filehandle)

    except IOError:
        logger.error("File does not exist or failed to read. [{0}]".format(
            filename)
        )

def load_multi_policy_file_from_S3(aws_region, policy_bucket_name, file_name):
    try:
        awshandler = AwsHandler(aws_region)
        s3_data = awshandler.download_data_from_s3(policy_bucket_name, file_name)
        decompressed_content = policyformatter.get_policy_binary(s3_data)
        logger.debug("Successfully retrieved policy file from S3 bucket [{0}] for file [{1}]".format(
            policy_bucket_name,
            file_name
        ))
        return json.loads(decompressed_content)

    except IOError:
        logger.error("File does not exist or failed to read. [{0}]".format(file_name))


def build_recipient_file_path(recipient, root_path):
    try:
        user_part, domain_part = recipient.split("@")
        return root_path + domain_part + "/" + base64.b64encode(user_part)
    except ValueError:
        logger.info("Invalid recipient address. [{0}]".format(
            recipient)
        )

def retrieve_policy_id_and_add_to_policy_list(customer_policy, policy_list, recipient):
    if customer_policy['policyId'] not in policy_list.keys():
        policy_list[customer_policy['policyId']] = [recipient]
    else:
        recipient_list = policy_list[customer_policy['policyId']]
        recipient_list.append(recipient)

    return policy_list

def retrieve_user_id_and_add_to_user_list(customer_policy, user_list,recipient):
    user_list[customer_policy['userId']] = [recipient]
    return user_list

def get_multi_policy_enabled():
    try:
        with open(EFS_MULTI_POLICY_CONFIG_FILE) as config_file:
            config_data = json.load(config_file)
            return config_data['multi.policy.enabled'] and config_data['multi.policy.enabled'] == "true"
    except IOError:
        return False

def get_read_from_s3_enabled():
    try:
        with open(FLAG_TO_READ_POLICY_FROM_S3_FILE) as flag_file:
            flag_data = json.load(flag_file)
            return flag_data['read.from.s3'] == "true"
    except IOError:
        return False

def get_user_based_split_enabled():
    try:
        with open(FLAG_TO_TOC_USER_BASED_SPLIT) as flag_file:
            flag_data = json.load(flag_file)
            return flag_data['toc.user.based.split.enabled'] == "true"
    except IOError:
        return False

def read_policy(recipient, aws_region, policy_bucket_name, read_from_s3):
    if (aws_region and policy_bucket_name and read_from_s3):
        logger.debug("ToC user based split, Reading policy for {0} directly from s3".format(recipient))
        begin_time = time.time()
        customer_policy = read_policy_from_S3(recipient, aws_region, policy_bucket_name)
    else:
        logger.debug("ToC user based split, Reading policy for {0} from EFS".format(recipient))
        begin_time = time.time()
        customer_policy = read_policy_from_EFS(recipient)

    elapsed_time = time.time() - begin_time
    elapsed_time = elapsed_time * 1000
    logger.debug("Policy_Read_MSG_PRODUCER result returned in {0} ms".format(elapsed_time))
    return customer_policy

def read_policy_endpoint(recipient, userid, aws_region, policy_bucket_name, read_from_s3):
    logger.debug("Reading endpoint policy for recipient {0} and userid {1}".format(recipient,userid))
    if (aws_region and policy_bucket_name and read_from_s3):
        endpoint_policy = read_endpoint_policy_from_S3(userid, aws_region, policy_bucket_name)
    else:
        endpoint_policy = read_endpoint_policy_from_EFS(userid)

    return endpoint_policy

def read_toc_config(recipient, endpoint_policy):
    try:
        policy_attributes = endpoint_policy['policyAttributes']
        is_toc_enabled = policy_attributes['xgemail/toc/enabled']
        logger.info("Recipient {0} has ToC on : {1}".format(recipient, is_toc_enabled))
        return is_toc_enabled
    except (IOError, KeyError, ValueError), e:
        logger.error("endpoint json parse / read error : {0}".format(e))
        return False
