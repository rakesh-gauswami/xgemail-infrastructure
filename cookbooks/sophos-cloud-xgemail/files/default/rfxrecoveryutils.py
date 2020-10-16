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
RFX_RECOVERY_IP = ["208.70.208.67", "208.70.208.68", "208.70.208.0/22", "69.84.129.224/27"]
INBOUND_MESSAGE_DIRECTION = "INBOUND"
OUTBOUND_MESSAGE_DIRECTION = "OUTBOUND"


def is_reflexion_ip(sender_ip):
    """
    :param sender_ip: Ip of the sender.
    :return: Boolean indicating if its reflexion IP or not.
    """
    for ip in RFX_RECOVERY_IP:
        if ipaddress.ip_address(unicode(sender_ip)) in ipaddress.ip_network(unicode(ip)):
            return True
    return False


def get_direction_for_recovered_mail(message_headers):
    """
    :param message_headers: Set of headers from message
    :return: direction for recovered mail from reflexion
    """
    is_reply = False  # Set to false to avoid -ENCR append in message path
    if message_headers[RFX_RECOVERY_DIRECTION_HEADER] is OUTBOUND_MESSAGE_DIRECTION or message_headers[
        RFX_RECOVERY_DIRECTION_HEADER] is RFX_JOURNAL:
        direction = OUTBOUND_MESSAGE_DIRECTION
    else:
        direction = INBOUND_MESSAGE_DIRECTION
    return direction, is_reply
