#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Base class for Sophos Central applications.
"""

import abc
import daemon
import daemon.pidfile
import logging
import os
import sys
import traceback

import sophos.common


def _get_logger_fds(logger, fds):
    """
    Helper function for _get_logging_fds.
    """

    if logger is None:
        return

    if not isinstance(logger, logging.Logger):
        return

    for handler in logger.handlers:
        # This is admittedly ugly.
        if isinstance(handler, logging.StreamHandler):
            fds.append(handler.stream.fileno())
        elif isinstance(handler, logging.handlers.SocketHandler):
            fds.append(handler.sock.fileno())
        elif isinstance(handler, logging.handlers.SysLogHandler):
            fds.append(handler.socket.fileno())

    _get_logger_fds(logger.parent, fds)


def get_logging_fds():
    """
    Return list of file descriptors used by log handlers.
    Needed to provide list of files descriptors to keep open when daemonizing.
    Warning: this function is not thread-safe.
    """

    fds = []

    for logger in logging.Logger.manager.loggerDict.values():
        _get_logger_fds(logger, fds)

    return fds


class AppBase(object):
    """
    Base class for applications.
    Subclass must define a start() method that executes desired code.
    Call the do_start method to initialize logging and call start() with
    appropriate exception handling.
    """

    __metaclass__ = abc.ABCMeta

    def setup_logging(self, application_name, log_dir, log_level):
        """
        Setup logging prior to starting the application.
        """

        logging.basicConfig(
                format=sophos.common.LOG_FORMAT,
                filename="%s/%s.log" % (log_dir, application_name),
                level=log_level)

    @abc.abstractmethod
    def start(self):
        pass

    def do_daemon(self, pid_path, init=None, body=None, step=None):
        """
        Convert the current process into a daemon that executes the init
        function and then alternately executes the body and step functions.

        pid_path is the path to a file that will store the process ID of the
        daemon process.  It is used for locking.

        init, body, and step are all functions or bound methods, or None.
        """

        pidfile = daemon.pidfile.PIDLockFile(pid_path)

        files_preserve = get_logging_fds()

        with daemon.DaemonContext(pidfile=pidfile, files_preserve=files_preserve):
            if init is not None:
                init()

            while True:
                try:
                    if body is not None:
                        body()

                except SystemExit as e:
                    logging.info("exit code: %s" % e.code)
                    raise

                except Exception as e:
                    # Swallow the error, try again later in case this is temporary.
                    logging.info("exception: %s" % str(e))
                    trace = traceback.format_exc()
                    for line in trace.splitlines():
                        logging.info(line)

                if step is not None:
                    step()

    def do_start(self, application_name=None, log_dir=None, verbose=False):
        """
        Start the application.
        """

        try:
            if application_name is None:
                application_name = os.path.basename(sys.argv[0])
                if application_name.endswith(".py"):
                    application_name = application_name[0:-3]

            if log_dir is None:
                log_dir = sophos.common.LOG_DIR

            self.setup_logging(application_name, log_dir, logging.DEBUG if verbose else logging.INFO)

            logging.info("launched: sys.argv: %s" % sys.argv)

            self.start()

        except SystemExit as e:
            logging.info("exit code: %s" % e.code)
            raise

        except Exception as e:
            trace = traceback.format_exc()
            for line in trace.splitlines():
                logging.info(line)
            raise

        except KeyboardInterrupt:
            sys.exit(1)
