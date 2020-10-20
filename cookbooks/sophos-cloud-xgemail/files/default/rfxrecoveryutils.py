#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2020, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Helper for all xgemail related utilities holder.
import ipaddress

RFX_JOURNAL = "JOURNAL"
RFX_RECOVERY_DIRECTION_HEADER = "X-MRP-Queue"
RFX_RECOVERY_IP = ["208.70.208.0/22"]
INBOUND_MESSAGE_DIRECTION = "INBOUND"
OUTBOUND_MESSAGE_DIRECTION = "OUTBOUND"


def is_reflexion_ip(sender_ip):
    """
    :param sender_ip: Ip of the sender.
    :return: Boolean indicating if its reflexion IP or not.
    """
    #This will not match exact IP, We have only CIDR for now.
    for ip in RFX_RECOVERY_IP:
        if ipaddress.ip_address(unicode(sender_ip)) in ipaddress.ip_network(unicode(ip)):
            return True
    return False


def get_direction_for_reflexion_mail(message_headers):
    """
    :param message_headers: Set of headers from message
    :return: direction for Reflexion mail based on header
    """
    # If direction header is missing then it is new email/forward/reply so treat it as outbound
    if message_headers.get(RFX_RECOVERY_DIRECTION_HEADER, None) is None:
        return OUTBOUND_MESSAGE_DIRECTION

    if message_headers[RFX_RECOVERY_DIRECTION_HEADER] is OUTBOUND_MESSAGE_DIRECTION or message_headers[
        RFX_RECOVERY_DIRECTION_HEADER] is RFX_JOURNAL:
        return OUTBOUND_MESSAGE_DIRECTION
    else:
        return INBOUND_MESSAGE_DIRECTION
