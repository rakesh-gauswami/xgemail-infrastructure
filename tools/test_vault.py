#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python
# module: test_vault

__author__ = 'cloud.inf@sophos.com'

"""
Test Ansible Vault Manager
A Service for Updating/Creating CloudFormation Stacks

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import logging
import mock
import sys
import unittest
import vault

from mock import call, patch
from subprocess import CalledProcessError, STDOUT


# Vault Test Case
class VaultTestCase(unittest.TestCase):
    check_output_cat = call(
        [
            "/bin/cat"
        ],
        stderr=STDOUT
    )
    check_output_decrypt_call = call(
        [
            '/usr/bin/ssh',
            'cod.cloud.sophos',
            'ansible-vault',
            'decrypt',
            '--vault-password-file=/var/vault_keys/foo/key.latest',
            '--output=-',
            'infrastructure.properties.yml'
        ],
        stderr=STDOUT
    )
    check_output_encrypt_call = call(
        [
            '/usr/bin/ssh',
            'cod.cloud.sophos',
            'ansible-vault',
            'encrypt',
            '--vault-password-file=/var/vault_keys/foo/key.latest',
            '--output=-',
            'infrastructure.properties.yml'
        ],
        stderr=STDOUT
    )
    check_output_delete_call = call(
        [
            "/usr/bin/ssh",
            "cod.cloud.sophos",
            "/usr/bin/rm",
            "infrastructure.properties.yml"
        ],
        stderr=STDOUT
    )
    check_output_scp_call = call(
        [
            "/usr/bin/scp",
            "ansible/roles/common/vars/foo/infrastructure.properties.yml",
            "cod.cloud.sophos:infrastructure.properties.yml"
        ],
        stderr=STDOUT
    )
    decrypted_contents = "Decrypted Contents"
    encrypted_contents = "$ANSIBLE ENCRYPTED CONTENTS"
    filepath = "ansible/roles/common/vars/foo/infrastructure.properties.yml"
    file_ext = "_vaulted.yml"

    def setUp(self):
        # Creat Mock Objects
        self.mocked_check_output      = mock.Mock()
        self.mocked_info              = mock.Mock()
        self.mocked_open              = mock.mock_open()
        self.mocked_stdout            = mock.Mock()
        self.mocked_stdout_write      = mock.Mock()
        self.mocked_stdout_flush      = mock.Mock()

        # This counts as a call, increment appropriately
        self.mocked_open_file         = self.mocked_open()

        # Wire Mocks
        self.mocked_stdout.write = self.mocked_stdout_write
        self.mocked_stdout.flush = self.mocked_stdout_flush

        # Create Test Objects
        self.error = CalledProcessError(1, "", output="ERROR: Ansible Error Message")

        # Patch
        self.patch_open         = patch('vault.open', self.mocked_open, create=True)
        self.patch_stdout       = patch.object(sys, "stdout", self.mocked_stdout)
        self.patch_info         = patch.object(logging, "info", self.mocked_info)
        self.patch_check_output = patch.object(vault, "check_output", self.mocked_check_output)

        self.patch_open.start()
        self.patch_stdout.start()
        self.patch_info.start()
        self.patch_check_output.start()

        # Initialize Class Under Test
        self.vault_manager = vault.AnsibleVaultManager()

    def tearDown(self):
        self.patch_check_output.stop()
        self.patch_info.stop()
        self.patch_stdout.stop()
        self.patch_open.stop()


# vault.AnsibleVaultManager.encrypt(filepath, git=False, env=None, key_rel_path=None)
class EncryptTest(VaultTestCase):
    def test_encrypt_succeeds(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.encrypted_contents, None]

        # Run
        self.vault_manager.encrypt(self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_encrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.encrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open.assert_called_with(self.filepath, 'w+')
        self.mocked_open_file.write.assert_called_once_with(self.encrypted_contents)

    def test_encrypt_hard_fails_with_scp_error(self):
        # Setup
        self.mocked_check_output.side_effect = [self.error, None]

        # Run
        self.assertRaises(CalledProcessError, self.vault_manager.encrypt, self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([self.check_output_scp_call, self.check_output_delete_call])
        self.mocked_stdout_write.assert_not_called()
        self.mocked_stdout_flush.assert_not_called()
        self.mocked_open_file.write.assert_not_called()

    def test_encrypt_soft_fails_with_ansible_error(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.error, None]
        self.mocked_open_file.read.return_value = self.decrypted_contents

        # Run
        self.vault_manager.encrypt(self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_encrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.decrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open_file.read.assert_called_with()
        self.mocked_open_file.write.assert_not_called()

    def test_encrypt_hard_fails_with_non_ansible_error(self):
        # Setup
        error = CalledProcessError(1, "", output="Something")
        self.mocked_check_output.side_effect = [None, error, None]

        # Run
        self.assertRaises(CalledProcessError, self.vault_manager.encrypt, self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_encrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_not_called()
        self.mocked_stdout_flush.assert_not_called()
        self.mocked_open_file.write.assert_not_called()

    def test_encrypt_hard_fails_with_remote_delete_error(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.encrypted_contents, self.error]

        # Run
        self.assertRaises(Exception, self.vault_manager.encrypt, self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_encrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.encrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open.assert_called_with(self.filepath, 'w+')
        self.mocked_open_file.write.assert_called_once_with(self.encrypted_contents)

    def test_encrypt_succeeds_using_git(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.encrypted_contents, None]

        # Run
        self.vault_manager.encrypt(self.filepath, self.file_ext, git=True)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_encrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.encrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open_file.write.assert_not_called()

    def test_encrypt_succeeds_using_env(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.encrypted_contents, None]
        check_output_encrypt_call = call(
            [
                '/usr/bin/ssh',
                'cod.cloud.sophos',
                'ansible-vault',
                'encrypt',
                '--vault-password-file=/var/vault_keys/bar/key.latest',
                '--output=-',
                'infrastructure.properties.yml'
            ],
            stderr=STDOUT
        )

        # Run
        self.vault_manager.encrypt(self.filepath, self.file_ext, env="bar")

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            check_output_encrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.encrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open.assert_called_with(self.filepath, 'w+')
        self.mocked_open_file.write.assert_called_once_with(self.encrypted_contents)

    def test_encrypt_succeeds_using_key_rel_path(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.encrypted_contents, None]
        check_output_encrypt_call = call(
            [
                '/usr/bin/ssh',
                'cod.cloud.sophos',
                'ansible-vault',
                'encrypt',
                '--vault-password-file=/var/vault_keys/foo/key.oldest',
                '--output=-',
                'infrastructure.properties.yml'
            ],
            stderr=STDOUT
        )

        # Run
        self.vault_manager.encrypt(self.filepath, self.file_ext, key_rel_path="key.oldest")

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            check_output_encrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.encrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open.assert_called_with(self.filepath, 'w+')
        self.mocked_open_file.write.assert_called_once_with(self.encrypted_contents)


# vault.AnsibleVaultManager.decrypt(filepath, git=False, env=None, key_rel_path=None)
class DecryptTest(VaultTestCase):
    def test_decrypt_succeeds(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.decrypted_contents, None]

        # Run
        self.vault_manager.decrypt(self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_decrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.decrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open.assert_called_with(self.filepath, 'w+')
        self.mocked_open_file.write.assert_called_once_with(self.decrypted_contents)

    def test_decrypt_hard_fails_with_scp_error(self):
        # Setup
        self.mocked_check_output.side_effect = [self.error, None]

        # Run
        self.assertRaises(CalledProcessError, self.vault_manager.decrypt, self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([self.check_output_scp_call, self.check_output_delete_call])
        self.mocked_stdout_write.assert_not_called()
        self.mocked_stdout_flush.assert_not_called()
        self.mocked_open_file.write.assert_not_called()

    def test_decrypt_soft_fails_with_ansible_error(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.error, None]
        self.mocked_open_file.read.return_value = self.decrypted_contents

        # Run
        self.vault_manager.decrypt(self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_decrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.decrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open_file.read.assert_called_with()
        self.mocked_open_file.write.assert_not_called()

    def test_decrypt_hard_fails_with_non_ansible_error(self):
        # Setup
        error = CalledProcessError(1, "", output="Something")
        self.mocked_check_output.side_effect = [None, error, None]

        # Run
        self.assertRaises(CalledProcessError, self.vault_manager.decrypt, self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_decrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_not_called()
        self.mocked_stdout_flush.assert_not_called()
        self.mocked_open_file.write.assert_not_called()

    def test_decrypt_hard_fails_with_with_remote_delete_error(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.decrypted_contents, self.error]

        # Run
        self.assertRaises(Exception, self.vault_manager.decrypt, self.filepath, self.file_ext)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            self.check_output_decrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.decrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open.assert_called_with(self.filepath, 'w+')
        self.mocked_open_file.write.assert_called_once_with(self.decrypted_contents)

    def test_decrypt_succeeds_using_git(self):
        # Setup
        self.mocked_check_output.side_effect = [self.encrypted_contents, None, self.decrypted_contents, None]
        check_output_scp_call = call(
            [
                "/usr/bin/scp",
                "ansible/roles/common/vars/foo/.ignore.infrastructure.properties.yml",
                "cod.cloud.sophos:infrastructure.properties.yml"
            ],
            stderr=STDOUT
        )

        # Run
        self.vault_manager.decrypt(self.filepath, self.file_ext, git=True)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_cat,
            check_output_scp_call,
            self.check_output_decrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_open.assert_called_with("ansible/roles/common/vars/foo/.ignore.infrastructure.properties.yml", "w+")
        self.mocked_open_file.write.assert_called_once_with(self.encrypted_contents)
        self.mocked_open_file.read.assert_not_called()
        self.mocked_stdout_write.assert_called_once_with(self.decrypted_contents)
        self.mocked_stdout_flush.assert_called_once()

    def test_decrypt_soft_fails_using_git_with_ansible_error(self):
        # Setup
        self.mocked_check_output.side_effect = [self.encrypted_contents, None, self.error, None]
        self.mocked_open_file.read.return_value = self.encrypted_contents
        check_output_scp_call = call(
            [
                "/usr/bin/scp",
                "ansible/roles/common/vars/foo/.ignore.infrastructure.properties.yml",
                "cod.cloud.sophos:infrastructure.properties.yml"
            ],
            stderr=STDOUT
        )

        # Run
        self.vault_manager.decrypt(self.filepath, self.file_ext, git=True)

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_cat,
            check_output_scp_call,
            self.check_output_decrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_open.assert_called()
        self.mocked_open_file.write.assert_called_once_with(self.encrypted_contents)
        self.mocked_open_file.read.assert_called_once()
        self.mocked_stdout_write.assert_called_once_with(self.encrypted_contents)
        self.mocked_stdout_flush.assert_called_once()

    def test_decrypt_succeeds_using_env(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.decrypted_contents, None]
        check_output_decrypt_call = call(
            [
                '/usr/bin/ssh',
                'cod.cloud.sophos',
                'ansible-vault',
                'decrypt',
                '--vault-password-file=/var/vault_keys/bar/key.latest',
                '--output=-',
                'infrastructure.properties.yml'
            ],
            stderr=STDOUT
        )

        # Run
        self.vault_manager.decrypt(self.filepath, self.file_ext, env="bar")

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            check_output_decrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.decrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open.assert_called_with(self.filepath, 'w+')
        self.mocked_open_file.write.assert_called_once_with(self.decrypted_contents)

    def test_decrypt_succeeds_using_key_rel_path(self):
        # Setup
        self.mocked_check_output.side_effect = [None, self.decrypted_contents, None]
        check_output_decrypt_call = call(
            [
                '/usr/bin/ssh',
                'cod.cloud.sophos',
                'ansible-vault',
                'decrypt',
                '--vault-password-file=/var/vault_keys/foo/key.oldest',
                '--output=-',
                'infrastructure.properties.yml'
            ],
            stderr=STDOUT
        )

        # Run
        self.vault_manager.decrypt(self.filepath, self.file_ext, key_rel_path="key.oldest")

        # Assert
        self.mocked_check_output.assert_has_calls([
            self.check_output_scp_call,
            check_output_decrypt_call,
            self.check_output_delete_call
        ])
        self.mocked_stdout_write.assert_called_once_with(self.decrypted_contents)
        self.mocked_stdout_flush.assert_called_once()
        self.mocked_open.assert_called_with(self.filepath, 'w+')
        self.mocked_open_file.write.assert_called_once_with(self.decrypted_contents)

if __name__ == "__main__":
    unittest.main()
