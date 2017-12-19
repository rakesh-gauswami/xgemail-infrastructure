#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
DEK CRUD Operations.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import logging
import re
import sys


# Exceptions
class HeaderException(Exception):
    pass


class InvalidHeaderException(HeaderException):
    pass


class HeaderAlreadyExistsException(HeaderException):
    pass


class DEKManager(object):

    # Note: Contains test values
    _header_format_re    = r"^\$DEK;([0-9]\.[0-9]);UID;(.*$)"
    _header_format_str   = "$DEK;%s;UID;%s"
    _header_format_human = "DEK Header Info\nFile: %s\nVersion: %s\nUID: %s\nFull Header: %s"

    def _parse_file(self, raw_filepath):
        # Get File Contents
        data = self._read_file(raw_filepath)

        # Get Header
        first_line = data.splitlines()[0]
        last_lines = '\n'.join(data.splitlines()[1:])

        # Check Header Contents
        header_obj = re.search(self._header_format_re, first_line)
        header = None
        version = None
        uid = None
        if header_obj is not None:
            header = first_line
            version = header_obj.group(1)
            uid = header_obj.group(2)
            data = last_lines

        return data, header, version, uid

    @classmethod
    def _read_file(cls, filepath):
        with open(filepath, 'r') as open_file:
            data = open_file.read()
        return data

    @classmethod
    def _write_stdout(cls, content):
        sys.stdout.write(content)
        sys.stdout.flush()

    def create(self, filepath, uid, version):
        try:
            logging.info("Create - Start: %s", filepath)
            data, existing_header, existing_version, existing_uid = self._parse_file(filepath)

            # Fail if header exists
            logging.info("Create - Check: %s", data)
            if existing_header is not None:
                raise HeaderAlreadyExistsException("Create - Exception: %s" % existing_header)

            # Create DEK header
            logging.info("Create - Version, UID: %s, %s", version, uid)
            header = self._header_format_str % (version, uid)

            # Append DEK header to "header"-less data
            logging.info("Create - Header: %s", header)
            data_with_header = header
            data_with_header += '\n'
            data_with_header += data

            # Write Contents to STDOUT
            logging.info("Create - Writing to STDOUT: %s", data_with_header)
            self._write_stdout(data_with_header)
        except Exception as e:
            logging.info("Create - Exception: %s", e.message)
            raise e

    def read(self, filepath):
        try:
            logging.info("Read - Start: %s", filepath)
            data, existing_header, existing_version, existing_uid = self._parse_file(filepath)

            # Fail if header is not valid
            logging.info("Read - Check: %s", data)
            if existing_header is None:
                raise InvalidHeaderException("Read - Exception: Expected format %s" % self._header_format_re)

            # Create DEK Data
            logging.info("Read - Version, UID: %s, %s", existing_version, existing_uid)
            read_data = self._header_format_human % (filepath, existing_version, existing_uid, existing_header)

            # Write Contents to STDOUT
            logging.info("Read - Writing to STDOUT: %s", read_data)
            self._write_stdout(read_data)
        except Exception as e:
            logging.info("Read - Exception: %s", e.message)
            raise e

    def update(self, filepath, uid, version):
        try:
            logging.info("Update - Start: %s", filepath)
            data, existing_header, existing_version, existing_uid = self._parse_file(filepath)

            # Fail if header is not valid
            logging.info("Update - Check: %s", data)
            if existing_header is None:
                raise InvalidHeaderException("Update - Exception: Expected format %s" % self._header_format_re)

            # Create DEK header
            logging.info("Update - Version, UID: %s, %s", version, uid)
            header = self._header_format_str % (version, uid)

            # Append DEK header to "header"-less data
            logging.info("Update - Header: %s", header)
            data_with_header = header
            data_with_header += '\n'
            data_with_header += data

            # Write Contents to STDOUT
            logging.info("Update - Writing to STDOUT: %s", data_with_header)
            self._write_stdout(data_with_header)
        except Exception as e:
            logging.info("Update - Exception: %s", e.message)
            raise e

    def delete(self, filepath):
        try:
            logging.info("Delete - Start: %s", filepath)
            data, existing_header, existing_version, existing_uid = self._parse_file(filepath)

            # Fail if header is not valid
            logging.info("Delete - Check: %s", data)
            if existing_header is None:
                raise InvalidHeaderException("Delete - Exception: Expected format %s" % self._header_format_re)

            # Write Contents to STDOUT
            logging.info("Delete - Writing to STDOUT: %s", data)
            self._write_stdout(data)
        except Exception as e:
            logging.info("Delete - Exception: %s", e.message)
            raise e


def parse_command_line():
    import argparse

    parser = argparse.ArgumentParser(
        description="Manage DEK Header.")

    parser.add_argument(
        "action", metavar="ACTION", type=str, help="one of: (create, read, update, delete).",
        choices=["create", "read", "update", "delete"]
    )
    parser.add_argument(
        "filepath", metavar="FILEPATH", type=str, help="path to the file to use."
    )
    parser.add_argument(
        "uid", metavar="UID", type=str,
        nargs="?", default="",
        help="UID of key (REQUIRED for Create/Update)"
    )
    parser.add_argument(
        "version", metavar="VERSION",
        nargs="?", default="",
        help="Version of header (REQUIRED for Create/Update)"
    )
    parser.add_argument("-l", "--log-file", dest="log_file", help="Log to LOG_FILE instead of stderr.")

    args = parser.parse_args()

    return args.action, args.filepath, args.uid, args.version, args.log_file


def main():
    action, filepath, uid, version, log_file = parse_command_line()

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    if log_file is not None:
        log_format = '%(asctime)s - %(levelname)s - %(message)s'
        log_handler = logging.FileHandler(log_file, mode="w")
    else:
        log_format = '%(message)s'
        log_handler = logging.StreamHandler(sys.stderr)

    log_handler.setFormatter(logging.Formatter(log_format))
    logger.addHandler(log_handler)

    dek_manager = DEKManager()

    if action == "create":
        if uid == "" or version == "":
            raise Exception("UID and Version must be set for create/update")
        dek_manager.create(filepath, uid, version)
    elif action == "read":
        dek_manager.read(filepath)
    elif action == "update":
        if uid == "" or version == "":
            raise Exception("UID and Version must be set for create/update")
        dek_manager.update(filepath, uid, version)
    elif action == "delete":
        dek_manager.delete(filepath)
    else:
        raise Exception("Invalid Action: %s" % action)

if __name__ == "__main__":
    main()
