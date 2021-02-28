#!/usr/bin/python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Provides KMS management helper objects and methods.
- KMSManager
"""

import sophos.aws

class KMSManager:
    def __init__(self, **kwargs):
        """
        :param kwargs (dict): aws_region,
                              aws_profile
        :return None
        :raises TypeError: Unkown parameter specified or parameter is missing
        """
        if kwargs is None:
            raise TypeError('No parameter specified!')

        for key, value in kwargs.iteritems():
            if key == 'aws_region':
                self._aws_region = value
            elif key == 'aws_profile':
                self._aws_profile = value
            else:
                raise TypeError('Unknown parameter found: [%s]' % key)

        self._aws_helper = sophos.aws.AwsHelper(session=sophos.aws.AwsSession(self._aws_profile, self._aws_region).create())
        self._client = self._aws_helper.add_client("kms", region=self._aws_region)

    @property
    def _kms_client(self):
        return self._client

    def _list_aliases(self):
        return self._kms_client.list_aliases()

    def get_key_id_from_alias(self, sse_key_alias):
        """
        Gets a list of KMS key aliases and returns the KMS master key id if found.
        :param sse_key_alias: the KMS alias name
        :type sse_key_alias: str
        :return: The sse key identifier
        :rtype: str if exists
        """
        aliases = self._list_aliases()["Aliases"]

        for alias in aliases:
            if ("alias/" + sse_key_alias) == alias["AliasName"]:
                return alias["TargetKeyId"]

        return None

    def get_key_id(self, sse_key_id):
        """
        Retrieves the master key id from KMS.
        :param sse_key_id: the KMS master key id
        :type sse_key_id: str
        :return: KMS master key id if exists, otherwise None
        :rtype: str if exists
        """
        keys = self._kms_client.list_keys()["Keys"]

        for key in keys:
            if key["KeyId"] == sse_key_id:
                return key["KeyId"]

        return None