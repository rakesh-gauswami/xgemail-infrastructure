# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

import logging
import sys

class Logger(object):
    def __init__(self, format_string=None):

        if format_string is None:
            self._s_format = "%(asctime)s [%(threadName)-12.12s] [%(levelname)-5.5s]  %(message)s"
        else:
            self._s_format = format_string

        self._init_object()

    def _init_object(self):

        self._logger = logging.getLogger()
        self._remove_handler()
        self._add_handler(self._formatter, logging.StreamHandler(sys.stdout))

    def _remove_handler(self):
        while len(self._logger.handlers) > 0:
            h = self._logger.handlers[0]
            self._logger.removeHandler(h)

    def _add_handler(self, formatter, handler):
        handler.setFormatter(formatter)

        self._logger.addHandler(handler)

        self._logger.setLevel(logging.INFO)

    @property
    def _formatter(self):
        return logging.Formatter(self._formatter_string)

    @property
    def _formatter_string(self):
        return self._s_format

    @_formatter_string.setter
    def _formatter_string(self, value):
        self._s_format = value

    def info(self, *arg):
        return self._logger.info(*arg)

    def warning(self, *arg):
        return self._logger.warning(*arg)

    def error(self, *arg):
        return self._logger.error(*arg)