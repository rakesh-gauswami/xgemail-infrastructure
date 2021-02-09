# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
This test code integrates multiple test cases that can be found
in the PyKMIP package in the 'demos' directory.

  - create
  - get
  - get_attributes
  - destroy

Execute:

  Prerequisite: kmip client config (https://github.com/OpenKMIP/PyKMIP)

  python test_create_key -c client -a AES -l 256

"""


import sys

from kmip.core import enums
from kmip.demos import utils

from kmip_client import KMIPClient
from kmip_logger import Logger


def main():

    logger = Logger()

    try:

        parser = utils.build_cli_parser(enums.Operation.CREATE)
        opts, args = parser.parse_args(sys.argv[1:])

        algorithm = opts.algorithm
        length = opts.length

        if algorithm is None:
            logger.error('No algorithm provided')
            sys.exit()
        if length is None:
            logger.error("No key length provided")
            sys.exit()

        logger.info("Connect to KeySecure...")

        kmip = KMIPClient()

        logger.info("Create the symmetric key...")

        uid = kmip.create_symmetric_key(opts.algorithm, opts.length, "keyname")

        logger.info("Retrieve key attributes...")

        kmip.get_attributes(uid)

        logger.info("Delete the symmetric key with uid:{}".format(uid))

        kmip.delete_symmetric_key(uid)


    except Exception as e:

        logger.info("Exception occurred:{}".format(e))

if __name__ == '__main__':
    main()
