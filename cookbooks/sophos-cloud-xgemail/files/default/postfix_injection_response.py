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
# Representation of the response obtained after injecting a message into postfix for delivery

class PostfixInjectionResponse:
    def __init__(self,
                 isSuccessfullyInjected,
                 nullableDeliveryQueueId):
        self.__isSuccessfullyInjected = isSuccessfullyInjected
        self.__nullableDeliveryQueueId = nullableDeliveryQueueId

    @property
    def is_successfully_injected(self):
        return self.__isSuccessfullyInjected

    @property
    def nullable_delivery_queue_id(self):
        return self.__nullableDeliveryQueueId

    def __str__(self):
        return "is_successfully_injected: %s, delivery_queue_id: %s" %(self.__isSuccessfullyInjected,
                                                                       self.__nullableDeliveryQueueId)

