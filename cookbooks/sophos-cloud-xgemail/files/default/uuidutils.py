#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# Helper for all xgemail related utilities holder.

import logging
import uuid

# logging to syslog setup
logger = logging.getLogger()
logger.setLevel(logging.INFO)

#gets the x-sophos-email-id from the header value
def get_x_sophos_email_id(x_sophos_email_id, queue_id):
    if x_sophos_email_id is None:
        logger.warning("Empty X-Sophos-Email-ID header in message with queue_id: [{0}]".format(queue_id))
        return None
    try:
        sophos_email_uuid = uuid.UUID(x_sophos_email_id)
        return str(sophos_email_uuid)
    except ValueError as e:
        logger.warning(
            "Invalid X-Sophos-Email-ID : [{0}], with queue_id: [{1}], failed to parse with error [{2}]  "
                .format(x_sophos_email_id, queue_id, e)
        )
        return None
