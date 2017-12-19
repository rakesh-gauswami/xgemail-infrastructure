#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
Interact with Ansible Vault Server.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import ConfigParser
import logging
import os
import re
import sys

from subprocess import check_output
from subprocess import CalledProcessError
from subprocess import STDOUT

"""
Test it like this, on your MacBook:

echo 'Alex plain text' > /tmp/0.txt

tools/vault.py -h

tools/vault.py -l /tmp/my.log -a dev -k test/alex.txt encrypt /tmp/0.txt > /tmp/1.dat
tools/vault.py                -a dev -k test/alex.txt encrypt /tmp/0.txt > /tmp/1.dat
tools/vault.py                -a inf                  encrypt /tmp/0.txt > /tmp/1.dat

tools/vault.py -l /tmp/my.log -a dev -k test/alex.txt decrypt /tmp/1.dat < /tmp/1.dat
tools/vault.py                -a dev -k test/alex.txt decrypt /tmp/1.dat < /tmp/1.dat
tools/vault.py                -a inf                  decrypt /tmp/1.dat < /tmp/1.dat
=>
Alex plain text
"""


class AnsibleVaultManager(object):

    # Note: Contains test values
    _err              = r"^ERROR"
    _key_rel_path     = "key.latest"
    _tmp_prefix       = ".ignore."
    _vault_cmd        = "ansible-vault"
    _vault_cmd_output = "--output=-"
    _vault_cmd_pass   = "--vault-password-file=/var/vault_keys/%s/%s"
    _vault_dns        = "cod.cloud.sophos"

    def __init__(self):
        config = ConfigParser.RawConfigParser()
        files = config.read(".check.vault.conf")

        # Read config if it exists
        if len(files) > 0:
            logging.info("Init - Setting Configuration")

            # Append _ to keys in config file
            for key, value in config.defaults().iteritems():
                logging.info("Init - Setting _%s: %s", key, value)
                self.__setattr__("_" + key, value)

    def _cat(self):
        try:
            cmd = ["/bin/cat"]
            return check_output(cmd, stderr=STDOUT)
        except CalledProcessError as e:
            logging.info("CAT - Exception: %s", e.output)
            raise e

    def _file_derive_metadata(self, raw_filepath):
        # Filename is last element of list
        filename = os.path.basename(raw_filepath)

        # Directory is everything but the file itself
        filedir = os.path.dirname(raw_filepath)

        # This is some ole bullshit right here
        # After getting the role, jump down three directories to get the account
        env = None
        filepath_obj = raw_filepath.split(os.sep)
        for filepath_key, filepath_part in enumerate(filepath_obj):
            if filepath_part == "roles":
                env = filepath_obj[filepath_key+3]
                break

        # Generate the temp file name but using the path with the filename and temp prefix
        tmp_filepath = os.path.join(filedir, self._tmp_prefix + filename)

        return filedir, env, filename, tmp_filepath

    def _read_file(self, filepath):
        with open(filepath, 'r') as open_file:
            data = open_file.read()
        return data

    def _remote_delete(self, filename):
        try:
            cmd = ["/usr/bin/ssh", self._vault_dns, "/usr/bin/rm", filename]
            logging.info("cmd: %s", ' '.join(cmd))
            check_output(cmd, stderr=STDOUT)
        except CalledProcessError as e:
            logging.info("Remote Delete of File %s May Have Failed, Please Confirm: %s", filename, e.output)
            raise e

    def _scp_upload(self, filepath, remote_filename):
        try:
            cmd = ["/usr/bin/scp", filepath, "%s:%s" % (self._vault_dns, remote_filename)]
            logging.info("cmd: %s", ' '.join(cmd))

            return check_output(cmd, stderr=STDOUT)
        except CalledProcessError as e:
            logging.info("SCP Upload - Exception: %s", e.output)
            raise e

    def _vault_decrypt(self, env, filename, key_rel_path=None):
        # If a key has been manually specified, use it
        if key_rel_path is None:
            key_rel_path = self._key_rel_path
        vault_cmd_pass = self._vault_cmd_pass % (env, key_rel_path)

        try:
            cmd = ["/usr/bin/ssh", self._vault_dns,
                   self._vault_cmd, "decrypt",  vault_cmd_pass, self._vault_cmd_output, filename]
            logging.info("cmd: %s", ' '.join(cmd))

            return check_output(cmd, stderr=STDOUT)
        except CalledProcessError as e:
            logging.info("Vault Decrypt - Exception: %s", e.output)

            # If the output matches the Ansible Error format, return None
            if re.search(self._err, e.output):
                return None
            raise e

    def _vault_encrypt(self, env, filename, key_rel_path=None):
        # If a key has been manually specified, use it
        if key_rel_path is None:
            key_rel_path = self._key_rel_path
        vault_cmd_pass = self._vault_cmd_pass % (env, key_rel_path)

        try:
            cmd = ["/usr/bin/ssh", self._vault_dns,
                   self._vault_cmd, "encrypt",  vault_cmd_pass, self._vault_cmd_output, filename]
            logging.info("cmd: %s", ' '.join(cmd))

            return check_output(cmd, stderr=STDOUT)
        except CalledProcessError as e:
            logging.info("Vault Encrypt - Exception: %s", e.output)

            # If the output matches the Ansible Error format, return None
            if re.search(self._err, e.output):
                return None
            raise e

    def _write_file(self, filepath, content):
        with open(filepath, 'w+') as open_file:
            open_file.write(content)

    def _write_stdout(self, content):
        sys.stdout.write(content)
        sys.stdout.flush()

    def _is_dir_or_file(self, filepath, file_ext):
        vaulted_files = []

        if os.path.isdir(filepath):
            for root, dirs, files in os.walk(filepath):
                for file in files:
                    if file.endswith(file_ext):
                        vaulted_files.append(os.path.join(root, file))
        else:
            vaulted_files.append(filepath)

        return vaulted_files

    def encrypt(self, filepath, file_ext, git=False, env=None, key_rel_path=None):
        uploaded_files = set()
        try:
            # If the filepath comes in as a directory, traverse the directory tree
            # and mark all *_vaulted.yml files for encryption by default
            vaulted_files = self._is_dir_or_file(filepath, file_ext)

            for filepath in vaulted_files:
                logging.info("Encrypt - Start: %s", filepath)
                new_content = True

                # If env has been manually specified, use it
                filedir, meta_env, filename, tmp_filepath = self._file_derive_metadata(filepath)
                if env is None:
                    env = meta_env

                # Upload file to Vault Controller
                logging.info("Encrypt - Vaulting: %s", filepath)
                uploaded_files.add(filename)
                self._scp_upload(filepath, filename)

                # Attempt to Vault the File on Vault Controller
                content = self._vault_encrypt(env, filename, key_rel_path)

                # If we receive None as the content, assume file is either already encrypted
                # or you do not have permission to encrypt, and use original file content
                if content is None:
                    content = self._read_file(filepath)
                    new_content = False

                # Write Contents to STDOUT
                logging.info("Encrypt - Writing to STDOUT: %s", filepath)
                self._write_stdout(content)

                # Overwrite if selected
                if not git and new_content:
                    self._write_file(filepath, content)
        except Exception as e:
            logging.info("Encrypt - Exception: %s", e.message)
            raise e
        finally:
            failed_files = []
            for uploaded_file in uploaded_files:
                try:
                    self._remote_delete(uploaded_file)
                except CalledProcessError:
                    failed_files.append(uploaded_file)
            if len(failed_files) > 0:
                err_msg = ", ".join(failed_files)
                raise Exception("Failed to Delete the Following Files: %s", err_msg)

    def decrypt(self, filepath, file_ext, git=False, env=None, key_rel_path=None):
        uploaded_files = set()
        try:
            # If the filepath comes in as a directory, traverse the directory tree
            # and mark all *_vaulted.yml files for decryption by default
            vaulted_files = self._is_dir_or_file(filepath, file_ext)

            for filepath in vaulted_files:
                logging.info("Decrypt - Start: %s", filepath)
                new_content = True

                # If env has been manually specified, use it
                filedir, meta_env, filename, tmp_filepath = self._file_derive_metadata(filepath)
                if env is None:
                    env = meta_env

                # If invoked manually, follow regular path
                if not git:
                    # Upload file to Vault Controller
                    logging.info("Decrypt - Unvaulting: %s", filepath)
                    uploaded_files.add(filename)
                    self._scp_upload(filepath, filename)

                # If invoked as git filter, use cat as read file will fail
                else:
                    # Read from STDIN
                    logging.info("Decrypt - Reading from STDIN: %s", filepath)
                    # cat works but not opening the file and reading
                    tmp_content = self._cat()

                    # Create Temp File
                    logging.info("Decrypt - Writing to Temp File: %s", tmp_filepath)
                    self._write_file(tmp_filepath, tmp_content)

                    # Upload file to Vault Controller
                    logging.info("Decrypt - Unvaulting: %s", tmp_filepath)
                    uploaded_files.add(filename)
                    self._scp_upload(tmp_filepath, filename)

                # Attempt to Unvault the File on Vault Controller
                content = self._vault_decrypt(env, filename, key_rel_path)

                # If we receive None as the content, assume file is either unencrypted
                # or you do not have permission to unencrypt, and use original file content
                if content is None:
                    new_content = False
                    if not git:
                        content = self._read_file(filepath)
                    else:
                        content = self._read_file(tmp_filepath)

                # Write Contents to STDOUT
                logging.info("Decrypt - Writing to STDOUT: %s", filepath)
                self._write_stdout(content)

                # Overwrite if selected
                if not git and new_content:
                    self._write_file(filepath, content)
        except Exception as e:
            logging.info("Decrypt - Exception: %s", filepath)
            raise e
        finally:
            failed_files = []
            for uploaded_file in uploaded_files:
                try:
                    self._remote_delete(uploaded_file)
                except CalledProcessError:
                    failed_files.append(uploaded_file)
            if len(failed_files) > 0:
                err_msg = ", ".join(failed_files)
                raise Exception("Failed to Delete the Following Files: %s", err_msg)


def parse_command_line():
    import argparse

    parser = argparse.ArgumentParser(
        description="Encrypts or decrypts files using Vault Server.")

    parser.add_argument(
        "action", metavar="ACTION", type=str, help="one of: (encrypt, decrypt).",
        choices=["encrypt", "decrypt"]
    )
    parser.add_argument(
        "filepath", metavar="FILEPATH", type=str, help="path to the file or directory to (en|de)crypt."
    )

    parser.add_argument(
        "-a", "--account", dest="aws_account", type=str, default=None,
        help="AWS account to use for crypto operations.")
    parser.add_argument(
        "-k", "--key-rel-path", dest="key_rel_path", type=str, default=None,
        help="The relative path of the encryption key in on AVC.")
    parser.add_argument(
        "-g", "--git", dest="git", action="store_true", default=None,
        help="When invoked as a git filter, read from stdin for decrypt, log to file and write results to STDOUT.")
    parser.add_argument(
        "-l", "--log-file", dest="log_file", type=str, default=".check.vault.log",
        help="Log file path (If manual is set, log to stderr)")
    parser.add_argument(
        "-e", "--extension", dest="file_ext", type=str, default="_vaulted.yml",
        help="File extension to (en|de)crypt within a directory.")

    args = parser.parse_args()

    return args.action, args.filepath, args.aws_account, args.key_rel_path, args.log_file, args.git, args.file_ext


def main():
    action, filepath, aws_account, key_rel_path, log_file, git, file_ext = parse_command_line()

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    if git:
        log_format = '%(asctime)s - %(levelname)s - %(message)s'
        log_handler = logging.FileHandler(log_file, mode="w")
    else:
        log_format = '%(message)s'
        log_handler = logging.StreamHandler(sys.stderr)

    log_handler.setFormatter(logging.Formatter(log_format))
    logger.addHandler(log_handler)

    vault_manager = AnsibleVaultManager()

    if action == "encrypt":
        vault_manager.encrypt(filepath, file_ext, git, aws_account, key_rel_path)
    elif action == "decrypt":
        vault_manager.decrypt(filepath, file_ext, git, aws_account, key_rel_path)
    else:
        raise Exception("Invalid Action: %s" % action)

if __name__ == "__main__":
    main()
