# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
AMI Bakery service

This implements an AMI bakery service similar to that used by Netflix.
See http://techblog.netflix.com/2016/03/how-we-build-code-at-netflix.html.
"""

import logging
import optparse
import time

import sophos.app

import bakery


def parse_command_line():
    """
    Parse command line, return options.
    """

    parser = optparse.OptionParser(
            usage="%prog [options]")

    parser.add_option(
            "-d", "--daemon", action="store_true", default=False,
            help="run continuously as a daemon")

    parser.add_option(
            "-v", "--verbose", action="store_true", default=False,
            help="verbose logging (at the DEBUG vs. INFO level)")

    options, args = parser.parse_args()

    if len(args) > 0:
        parser.error("too many arguments")

    return options


class App(sophos.app.AppBase):
    """
    AMI Bakery application object.
    """

    def __init__(self, options):
        self.options = options
        self.baker = bakery.Baker()

        logging.getLogger("botocore").setLevel(logging.INFO)

    def daemon_body(self):
        logging.info("Checking for new requests.")
        message = self.baker.receive_message()

        if message is not None:
            logging.info("Processing message.")
            self.baker.process_message(message)

        logging.info("Performing self-maintenance.")
        self.baker.perform_maintenance()

    def daemon_step(self):
        # "Time is nature's way to keep everything from happening all at once".
        # -- Ray Cummings
        time.sleep(1)

    def start(self):
        if self.options.daemon:
            self.do_daemon(
                    "/var/run/ami_bakery/ami_bakery.pid",
                    body=self.daemon_body,
                    step=self.daemon_step)
        else:
            self.daemon_body()


def main():
    options = parse_command_line()
    app = App(options)
    app.do_start(verbose=app.options.verbose)
