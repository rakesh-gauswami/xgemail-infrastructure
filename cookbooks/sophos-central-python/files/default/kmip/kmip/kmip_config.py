# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.


class KMIPClientConfig(object):
    """
    The configuration class can be used to provide
    client configuration settings programmatically.

    The KMIP client supports loading configuration
    settings from a configuration file too. Please
    look at the documentation of ProxyKmipClient or
    KmipClient implementation.

    """

    def __init__(self):
        self._hostname = None;
        self._port = None;
        self._ssl_version = None
        self._cert = None
        self._key = None
        self._cafile = None
        self._username = None
        self._password = None

    @property
    def hostname(self):
        return self._hostname

    @hostname.setter
    def hostname(self, value):
        self._hostname = value

    @property
    def port(self):
        return self._port

    @port.setter
    def port(self, value):
        self._port = value

    @property
    def ssl_version(self):
        return self._ssl_version

    @port.setter
    def ssl_version(self, value):
        self._ssl_version = value

    @property
    def cert(self):
        return self._cert

    @cert.setter
    def cert(self, value):
        self._cert = value

    @property
    def key(self):
        return self._key;

    @key.setter
    def key(self, value):
        self._key = value

    @property
    def cafile(self):
        return self._cafile

    @cafile.setter
    def cafile(self, value):
        self._cafile = value

    @property
    def username(self):
        return self._username;

    @username.setter
    def username(self, value):
        self._username = value

    @property
    def password(self):
        return self._password;

    @password.setter
    def password(self, value):
        self._password = value