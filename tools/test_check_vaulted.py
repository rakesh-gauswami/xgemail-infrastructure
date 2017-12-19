#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Unit tests for the check_vaulted utility.
"""

# Import test module FIRST to make sure there are no dependencies.
import check_vaulted

import cStringIO
import textwrap
import unittest

class CheckVaultedTest(unittest.TestCase):
    """
    Unit tests for the check_vaulted utility.
    """

    def check_vaulted(self, path, text):
        err = cStringIO.StringIO()
        result = check_vaulted.check_vaulted(path, text, err)
        message = err.getvalue()
        return result, message

    def test_good_vaulted_file(self):
        text = textwrap.dedent("""
		$ANSIBLE_VAULT;1.1;AES256
		37643232633464343765316439363732613432306463633331353337653035383538353433613866
		6233386335393339396235333465376535643231373030360a663534663038366665353735306564
		65363630326434626361346237356562393232336463366235363235636531393163373762333663
		6538326162623333310a396235613432303361623962666266323139306332343362323666383935
		39663563366138633133306231396362353239613232393136636539346532333830336432363562
		62633466646562363131636130373238396237613033383239336664333062383361633464373638
		31666438663634386262663132376434366432356432393832343838626662386438363430613465
		61613639656364643065616234643365613435373830633137383332663733303166356639356130
		39643761613862336538346138376661373962373462326338353463313333616333
        """).strip()
        result, message = self.check_vaulted("good_vaulted.yml", text)
        self.assertEqual((result, message), (True, ""))

    def test_no_content(self):
        text = ""
        result, message = self.check_vaulted("bad_vaulted.yml", text)
        self.assertEqual((result, message), (False, "bad_vaulted.yml:0: no content\n"))

    def test_no_vault_header(self):
        text = textwrap.dedent("""
        hub:
            region: eu-west-1
        """).strip()
        result, message = self.check_vaulted("bad_vaulted.yml", text)
        self.assertEqual((result, message), (False, "bad_vaulted.yml:1: no leading vault header\n"))

    def test_unexpected_content(self):
        text = textwrap.dedent("""
		$ANSIBLE_VAULT;1.1;AES256
		37643232633464343765316439363732613432306463633331353337653035383538353433613866
		6233386335393339396235333465376535643231373030360a663534663038366665353735306564
		65363630326434626361346237356562393232336463366235363235636531393163373762333663
		6538326162623333310a396235613432303361623962666266323139306332343362323666383935
		39663563366138633133306231396362353239613232393136636539346532333830336432363562
		62633466646562363131636130373238396237613033383239336664333062383361633464373638
		31666438663634386262663132376434366432356432393832343838626662386438363430613465
		61613639656364643065616234643365613435373830633137383332663733303166356639356130
		39643761613862336538346138376661373962373462326338353463313333616333 ptui!
        """).strip()
        result, message = self.check_vaulted("bad_vaulted.yml", text)
        self.assertEqual((result, message), (False, "bad_vaulted.yml:10: unexpected content\n"))

if __name__ == "__main__":
    unittest.main()
