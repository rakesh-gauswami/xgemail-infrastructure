# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

from kmip.core import enums
from kmip.core.factories import attributes
from kmip.pie import client

from kmip_interfaces import KMIPInterface
from kmip_logger import Logger


class KMIPClient(KMIPInterface):
    """
    The KMIPClient wrapper class abstracts KMIP client core implementations. The implementation
    has to fulfill the KMIPInterface contract, type safety is not guaranteed.

    """

    def __init__(self, impl=None):

        self._client = impl
        self._config = None
        self._logger = Logger()
        self._attribute_factory = attributes.AttributeFactory()

    @property
    def config(self):

        return self._config

    @config.setter
    def config(self, value):

        self._config = value

    def _kmip_impl(self):

        if self._client is None:
            if self._config is None:
                self._client = client.ProxyKmipClient()
            else:
                self._client = client.ProxyKmipClient(self.config.hostname, self.config.port,
                                                  self.config.cert, self.config.key,
                                                  self.config.cafile, self.config.ssl_version,
                                                  self.config.username, self.config.password)

        return self._client

    # TBD: internal method that adds attributes to the symmetric key blob,
    # or implement an "add_attributes() functions"
    def _create_symmetric_key(self, alg, len, keyName):

        with self._kmip_impl() as kmip:
            try:
                uid = kmip.create(self._get_algorithm_enum(alg), len)
                self._logger.info("Successfully created a symmetric key: %s " % uid)
                return uid
            except Exception as e:
                self._logger.error("Key couldn't be created, details={}".format(e))
                raise

    # Returns the proper enum used internally
    def _get_algorithm_enum(self, value):

        return getattr(enums.CryptographicAlgorithm, value, None)

    # Returns the object's attributes
    def get_attributes(self, uid):

        with self._kmip_impl() as kmip:
            try:
                list_attributes = kmip.get_attribute_list(uid)
                self._logger.info("Successfully retrieved attribute list: {}".format(list_attributes))
                return list_attributes
            except Exception as e:
                self._logger.error("Key attributes not retrieved, details={}".format(e))
                raise

    # Creates a symmetric key
    def create_symmetric_key(self, alg, len, keyName):

        return self._create_symmetric_key(alg,len,keyName)

    # Deletes a symmetric key
    def delete_symmetric_key(self, uid):

        with self._kmip_impl() as kmip:
            try:
                kmip.destroy(uid)
                self._logger.info("Successfully destroyed key: {}".format(uid))
                return uid
            except Exception as e:
                self._logger.error("Key couldn't be deleted, details={}".format(e))
                raise
