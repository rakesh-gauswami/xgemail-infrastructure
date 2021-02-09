# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

class KMIPInterface (object):
    @property
    def config(self):
        raise NotImplementedError("KMIPINterface::get_config")

    @config.setter
    def config(self, value):
        raise NotImplementedError("KMIPINterface::set_config")

    def get_attributes(self, uid):
        raise NotImplementedError("KMIPINterface::connect")

    def create_symmetric_key(self, alg, len, keyName):
        raise NotImplementedError("KMIPINterface::create_symmetric_key")

    def delete_symmetric_key(self, uid):
        raise NotImplementedError("KMIPINterface::delete_symmetric_key")