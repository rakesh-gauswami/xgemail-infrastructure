#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Xgemail diskutils utility.

Copyright 2019, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import logging
import sys
import tempfile
import unittest

from logging.handlers import SysLogHandler

try:
    import mock
except ImportError:
    # Python 2.x doesn't provide the above module as part of its standard library.
    #
    # In order to run this unit test on your local machine, you need to install
    # the mock library as explained here: https://pypi.org/project/mock
    print 'mock library not installed. Skipping these unit tests.'
    sys.exit(0)

# on OSX, the file /dev/log does not exist and needs to be changed to /var/run/syslog
if sys.platform.startswith('darwin'):
    with mock.patch('__main__.logging.handlers.SysLogHandler', create=True) as mocked_logging:
        mocked_logging.return_value = logging.handlers.SysLogHandler(address='/var/run/syslog')
        import s3recipientreader
else:
    import s3recipientreader

class S3RecipientReaderTest(unittest.TestCase):
    def setUp(self):
        # Create a temporary directory
        self.empty_dir = tempfile.mkdtemp()

    def test_decode_email_address(self):
        self.assertEqual(
            s3recipientreader.decode_email_address('config/policies/domains/lion.com/aGFrdW5hLm1hdGF0YQ=='),
            'hakuna.matata@lion.com'
        )

if __name__ == "__main__":
    unittest.main()
