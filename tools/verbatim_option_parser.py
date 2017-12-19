# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

"""
OptionParser subclass with more formatting control.

Copyright 2016, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""


import optparse


class VerbatimOptionParser(optparse.OptionParser):
    """OptionParser subclass with verbatim description and epilog formatting."""

    def format_description(self, _):
        if self.description:
            expanded = self.expand_prog_name(self.description)
            return expanded.strip() + "\n"
        else:
            return ""

    def format_epilog(self, _):
        if self.epilog:
            expanded = self.expand_prog_name(self.epilog)
            return "\n" + expanded.strip() + "\n"
        else:
            return ""
