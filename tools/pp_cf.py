#!/usr/bin/python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Pretty-print AWS CloudFormation templates.

This is an opionated module, which is a fancy way of saying that
it doesn't provide a bazillion options to tweak every possible decision.
"""

import StringIO
import os
import re
import simplejson
import sys
import time

DEFAULT_INDENT = 4

DEFAULT_WIDTH = 120

ORDER_ALPHA = "alpha"
ORDER_SOURCE = "source"
CHOICES_ORDER = [ORDER_ALPHA, ORDER_SOURCE]
DEFAULT_ORDER = ORDER_ALPHA

# Common exception for reporting JSON parsing errors from various sources.
class JsonError(Exception):
    pass

# Tokenize JSON text, yielding (token_type, token_text) tuples.
# Use to determine positions of Resource entries when output
# is sorted by source position.
def iter_json_tokens(text):
    RE_SPACES = re.compile(r'[ \t]*')

    RULES = [
        # Numbers.
        ("N", re.compile(r'-?\d+(\.\d+)?')),
        # Quoted strings.
        ("S", re.compile(r'"(\\.|[^"])*"')),
        # Keywords (all 3 of them).
        ("K", re.compile(r'\b(true|false|null)\b')),
        # Punctuation.
        ("P", re.compile(r'[{:}\[,\]]')),
    ]

    lineno = 0
    for line in text.splitlines():
        lineno += 1
        pos = 0
        while True:
            pos = RE_SPACES.match(line, pos).end()
            if pos >= len(line):
                break

            match = None
            for token_type, token_re in RULES:
                match = token_re.match(line, pos)
                if match is not None:
                    yield (token_type, match.group(0))
                    pos = match.end()
                    break

            if match is None:
                raise JsonError("invalid JSON token: line %d char %d (%r...)" % (lineno, pos + 1, line[pos]))

# Add copyright notice to data for given year, unless one is already present.
def add_copyright(data, year):
    if "Metadata" not in data:
        data["Metadata"] = {}

    if "Copyright" not in data["Metadata"]:
        data["Metadata"]["Copyright"] = [
            "Copyright %s, Sophos Limited. All rights reserved." % year,
            "",
            "'Sophos' and 'Sophos Anti-Virus' are registered trademarks of",
            "Sophos Limited and Sophos Group.  All other product and company",
            "names mentioned are trademarks or registered trademarks of their",
            "respective owners."
        ]

# Read content of file at given path or sys.stdin.
def slurp(path=None):
    if path is None:
        return sys.stdin.read()
    with open(path) as fp:
        return fp.read()

# Return true if breadcrumbs ends with or exactly matches pattern,
# where None in a pattern is an automatic match at that position.
def match_breadcrumbs(breadcrumbs, pattern, exact=False):
    offset = len(breadcrumbs) - len(pattern)

    if offset < 0:
        return False    # pattern is too long

    if exact and offset != 0:
        return False    # cannot be an exact match

    for i, pat in enumerate(pattern):
        if pat is None:
            continue
        if breadcrumbs[i + offset] != pat:
            return False

    return True

# Return list of keys for dictionary entries that should print first
# given the current location as stored in the breadcrumbs list.
def first_keys(breadcrumbs, resources_order, text):
    if match_breadcrumbs(breadcrumbs, [], exact=True):
        return [
            "AWSTemplateFormatVersion",
            "Description",
            "Metadata",
            "Parameters",
            "Mappings",
            "Conditions",
            "Resources",
            "Outputs",
        ]

    if match_breadcrumbs(breadcrumbs, ["Metadata"]):
        return [
            "Copyright",
            "Comments",
            "Comment"
        ]

    if match_breadcrumbs(breadcrumbs, ["Resources"], exact=True):
        if resources_order == ORDER_SOURCE:
            # Tokenize text and extract Resource entry keys.
            keys = []
            depth = 0
            section = None
            for token in iter_json_tokens(text):
                if token == ("P", "{"):
                    depth += 1
                elif token == ("P", "}"):
                    depth -= 1
                elif depth == 1 and token[0] == "S":
                    section = simplejson.loads(token[1])
                elif depth == 2 and token[0] == "S" and section == "Resources":
                    key = simplejson.loads(token[1])
                    keys.append(key)
            return keys
        else:
            return None

    if match_breadcrumbs(breadcrumbs, ["Parameters", None], exact=True):
        return [
            "Description",
            "NoEcho",
            "Type",
            "Default",
            "AllowedValues",
            "AllowedPattern",
            "ConstraintDescription",
            "MaxLength",
            "MinValue",
            "MaxValue",
        ]

    if match_breadcrumbs(breadcrumbs, ["Resources", None], exact=True):
        return [
            "Type",
            "DependsOn",
            "CreationPolicy",
            "UpdatePolicy",
            "Version",
        ]

    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Authentication", None]):
        return [
            "type",
            "uris",
            "username",
            "password",
            "buckets",
            "roleName",
            "accessKeyId",
            "secretKey",
        ]

    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init"]):
        return [
            "configSets"
        ]

    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init", None]):
        return [
            "packages",
            "groups",
            "users",
            "sources",
            "files",
            "commands",
            "services",
        ]

    # Fix order for cfn-init packages entries.
    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init", None, "packages"]):
        return [
            "msi",
            "rpm",
            "yum",
            "apt",
            "python",
            "rubygems"
        ]

    # Fix order for cfn-init files entries.
    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init", None, "files", None]):
        return [
            "content",
            "context",
            "source",
            "authentication",
            "encoding",
            "owner",
            "group",
            "mode",
        ]

    if match_breadcrumbs(breadcrumbs, ["Resources", None, "Properties"], exact=True):
        return [
            "ServiceToken",
            "GroupId",
            "IpProtocol",
            "CidrIp",
            "FromPort",
            "ToPort",
            "DestinationSecurityGroupId",
            "SourceSecurityGroupId",
        ]

    if match_breadcrumbs(breadcrumbs, ["Properties", "Tags", None]):
        return [
            "Key",
            "Value",
        ]

    if match_breadcrumbs(breadcrumbs, ["Properties", "DistributionConfig", "Origins", None]):
        return [
            "Id",
        ]

    if match_breadcrumbs(breadcrumbs, ["Properties", "DistributionConfig", "DefaultCacheBehavior"]):
        return [
            "TargetOriginId",
        ]

    if match_breadcrumbs(breadcrumbs, ["Properties", "SecurityGroupEgress", "#"]):
        return [
            "IpProtocol",
            "CidrIp",
            "FromPort",
            "ToPort",
            # CF doesn't seem to enforce the Destination for egress, Source for ingress.
            "DestinationSecurityGroupId",
            "SourceSecurityGroupId",
            "SourceSecurityGroupName",
            "SourceSecurityGroupOwnerId",
        ]

    if match_breadcrumbs(breadcrumbs, ["Properties", "SecurityGroupIngress", "#"]):
        return [
            "IpProtocol",
            "CidrIp",
            "FromPort",
            "ToPort",
            # CF doesn't seem to enforce the Destination for egress, Source for ingress.
            "DestinationSecurityGroupId",
            "SourceSecurityGroupId",
            "SourceSecurityGroupName",
            "SourceSecurityGroupOwnerId",
        ]

    if match_breadcrumbs(breadcrumbs, ["Properties", "PolicyDocument"]):
        return [
            "Id",
            "Version",
        ]

    if match_breadcrumbs(breadcrumbs, ["Properties", "PolicyDocument", "Statement", "#"]):
        return [
            "Sid",
            "Effect",
            "Action",
            "Principal",
            "Resource",
            "Condition"
        ]

    return None

# Return list of (index, key, value) tuples for the given data dictionary
# with keys in the first_keys list appearing first and any remaining keys
# appearing alphabetically.
def items_in_preferred_order(data, first_keys):
    items = []
    index = 0

    if first_keys is not None:
        for key in first_keys:
            if key in data:
                items.append((index, key, data[key]))
                index += 1

    for key in sorted(data.keys()):
        if first_keys is not None:
            if key in first_keys:
                continue
        items.append((index, key, data[key]))
        index += 1

    return items

# Return whether entries in the current context should have blank lines between them.
def should_double_space(level, breadcrumbs):
    if level < 2:
        return True

    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init"]):
        return True

    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init", "configSets"]):
        return False

    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init", None]):
        return True

    return False

# Return whether values in the current dict should be aligned at a common column.
def should_align_values(breadcrumbs):
    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init", "configSets"]):
        return True

    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init", None, "files", None, "context"]):
        return True

    if match_breadcrumbs(breadcrumbs, ["Metadata", "AWS::CloudFormation::Init", None, "files", None]):
        return True

    return False

# Return whether a list of dictionaries should be printed compactly.
def should_compact_dictionary_list(breadcrumbs):
    if match_breadcrumbs(breadcrumbs, ["Fn::And"]):
        return False

    if match_breadcrumbs(breadcrumbs, ["Fn::Or"]):
        return False

    return True

# Return number of characters written so far to the current output line.
def current_column(output):
    lines = output.getvalue().splitlines()
    if len(lines) == 0:
        return 0
    else:
        return len(lines[-1])

# Return True if value is neither a dict nor a list.
def is_scalar(value):
    if isinstance(value, dict):
        return False
    if isinstance(value, list):
        return False
    return True

# Return a formatted value suitable for printing, or None
# if value is not a scalar.
def format_scalar(value):
    if is_scalar(value):
        return simplejson.dumps(value)
    return None

# Return a formatted value suitable for printing, or None
# if value is not a scalar or a simple dict or list.
def format_simple(value, lists_too=False):
    if is_scalar(value):
        return simplejson.dumps(value)

    if isinstance(value, dict):
        if len(value) == 0:
            return "{}"
        if len(value) == 1:
            k, v = value.items()[0]
            if is_scalar(k):
                if is_scalar(v):
                    return "{ " + simplejson.dumps(k) + ": " + simplejson.dumps(v) + " }"

    if isinstance(value, list):
        if len(value) == 0:
            return "[]"
        if lists_too:
            formatted_values = []
            for v in value:
                formatted_value = format_simple(v)
                if formatted_value is None:
                    return None
                formatted_values.append(formatted_value)
            return "[ " + ", ".join(formatted_values) + " ]"

    return None

class CloudFormationPrettyPrinter(object):
    def __init__(self, copyright=False, year=None, squeeze=False, indent=DEFAULT_INDENT, width=DEFAULT_WIDTH, order=DEFAULT_ORDER):
        # Force exception when passing bool or string value in integer context.
        if isinstance(indent, (bool, basestring)):
            indent = None
        if isinstance(width, (bool, basestring)):
            width = None

        self.copyright = copyright

        self.year = year
        if self.year is None:
            self.year = time.strftime("%Y")

        self.squeeze = squeeze

        self.indent = int(indent)
        self.indent_segment = " " * self.indent

        self.width = int(width)

        self.order = str(order)
        if self.order not in CHOICES_ORDER:
            raise ValueError("invalid order value")

        self.text = None

    def _indent_prefix(self, level):
        # Return indent prefix string to use at given level.
        # We could cache return values but I doubt that would make much difference.

        return self.indent_segment * level

    def _print_without_wrapping(self, output, *args):
        # Print args IFF no arg is None and the resulting line width < self.width.
        # Return True if this was possible, else False.

        for arg in args:
            if arg is None:
                return False

        width_estimate = current_column(output)
        for arg in args:
            width_estimate += len(arg)

        if width_estimate >= self.width:
            return False

        for arg in args:
            output.write(arg)

        return True

    def _print_dict_compactly(self, output, level, data, breadcrumbs,
            indent_prefix, entry_prefix, keys, items):
        # Try to print a dictionary object to the output stream compactly.
        # Return True if successful, else False.

        if len(items) == 1:
            i, key, value = items[0]

            # Squeeze dictionaries mapping a scalar to a scalar onto one line.
            if self._print_without_wrapping(
                    output,
                    "{ ",
                    format_scalar(key),
                    ": ",
                    format_simple(value),
                    " }"):
                return True

            # Squeeze dictionaries mapping an intrinsic function to a list onto one line.
            if key.startswith("Fn::"):
                if isinstance(value, list):
                    args = ["{ ", simplejson.dumps(key), ": [ "]
                    for i, v in enumerate(value):
                        if i > 0:
                            args.append(", ")
                        args.append(format_simple(v))
                    args.append(" ] }")
                    if self._print_without_wrapping(output, *args):
                        return True

            # Squeeze simple calls to Fn::Join.
            if key == "Fn::Join":
                if isinstance(value, list):
                    if len(value) == 2:
                        delimiter, args = value
                        if isinstance(delimiter, basestring):
                            if isinstance(args, list):
                                output.write("{\n")
                                output.write(entry_prefix)
                                output.write(simplejson.dumps(key))
                                output.write(": [ ")
                                output.write(simplejson.dumps(delimiter))
                                output.write(", ")
                                self._print_list(output, level + 1, args, breadcrumbs + [key])
                                output.write("]\n")
                                output.write(indent_prefix)
                                output.write("}")
                                return True

        return False


    def _print_dict(self, output, level, data, breadcrumbs):
        # Print a dictionary object to the output stream.

        if len(data) == 0:
            output.write("{}")
            return

        indent_prefix = self._indent_prefix(level)
        entry_prefix = self._indent_prefix(level + 1)

        keys = first_keys(breadcrumbs, self.order, self.text)
        items = items_in_preferred_order(data, keys)

        # Perform minor optimizations to squeeze output a little bit.
        if self.squeeze:
            if self._print_dict_compactly(output, level, data, breadcrumbs, indent_prefix, entry_prefix, keys, items):
                return

        output.write("{\n")

        # Determine target start column for values, if any.
        value_column = None
        if should_align_values(breadcrumbs):
            max_key_width = 0
            for _, key, _ in items:
                max_key_width = max(max_key_width, len(simplejson.dumps(key)))
            value_column = len(entry_prefix) + max_key_width + 2

        for i, key, value in items:
            if should_double_space(level, breadcrumbs):
                if i > 0:
                    output.write("\n")

            output.write(entry_prefix)
            output.write(simplejson.dumps(key))
            output.write(": ")

            if value_column is not None:
                extra_indent = value_column - current_column(output)
                if extra_indent > 0:
                    output.write(" " * extra_indent)

            self._print_value(output, level + 1, value, breadcrumbs + [key])
            if i < len(items) - 1:
                output.write(",")
            output.write("\n")

        output.write(indent_prefix)
        output.write("}")

    def _print_list_compactly(self, output, level, data, breadcrumbs):
        # Try to print a list object to the output stream compactly.
        # Return True if successful, else False.

        # Squeeze short lists of simple types onto one line.
        # Width estimate must include "[ " and " ]" on either end
        # and ", " between items.
        simple_list = True
        simple_print_args = []
        if len(data) <= 1:
            for i, value in enumerate(data):
                if not is_scalar(value):
                    simple_list = False
                    break
                # The following statement is a no-op now that we don't squeeze
                # lists longer than 1 element, but is preserved here in case
                # we change our mind.
                if i > 0:
                    simple_print_args.append(", ")
                simple_print_args.append(simplejson.dumps(value))
            if simple_list:
                simple_print_args.insert(0, "[ ")
                simple_print_args.append(" ]")
                if self._print_without_wrapping(output, *simple_print_args):
                    return True

        # Squeeze list containing a single simple dict onto one line.
        if len(data) == 1:
            if isinstance(data[0], dict) and len(data[0]) == 1:
                key = data[0].keys()[0]
                value = data[0].values()[0]
                if is_scalar(key) and is_scalar(value):
                    if self._print_without_wrapping(
                            output,
                            "[{ ",
                            simplejson.dumps(key),
                            ": ",
                            simplejson.dumps(value),
                            " }]"):
                        return True

        # Print lists of multiple-entry dictionaries compactly.
        # TODO: This needs better handling, we shouldn't need to special case Fn::And and Fn::Or.
        if should_compact_dictionary_list(breadcrumbs):
            multiple_entry_dictionary_list = True
            for value in data:
                if not isinstance(value, dict):
                    multiple_entry_dictionary_list = False
                    break
                # If the first item is going to be printed as a single line, then
                # don't squeeze, the end result will be weird.  That can be a bummer
                # but it's easier to check here then disable the squeeze of the
                # item to one line based on current context.
                if len(value) == 1:
                    k = value.keys()[0]
                    v = value[k]
                    if is_scalar(k):
                        if is_scalar(v):
                            multiple_entry_dictionary_list = False
                            break
                    if k == "Fn::GetAtt":
                        if isinstance(v, list):
                            if len(v) == 2:
                                if isinstance(v[0], basestring):
                                    if isinstance(v[1], basestring):
                                        multiple_entry_dictionary_list = False
                                        break
            if multiple_entry_dictionary_list:
                output.write("[")
                for i, value in enumerate(data):
                    self._print_value(output, level, value, breadcrumbs + ["#"])
                    if i < len(data) - 1:
                        output.write(", ")
                output.write("]")
                return True

        return False

    def _print_list(self, output, level, data, breadcrumbs):
        # Print a list object to the output stream.

        if len(data) == 0:
            output.write("[]")
            return

        if self.squeeze:
            if self._print_list_compactly(output, level, data, breadcrumbs):
                return

        output.write("[\n")

        for i, value in enumerate(data):
            entry_prefix = self._indent_prefix(level + 1)
            output.write(entry_prefix)

            self._print_value(output, level + 1, value, breadcrumbs + ["#"])
            if i < len(data) - 1:
                output.write(",")
            output.write("\n")

        indent_prefix = self._indent_prefix(level)
        output.write(indent_prefix)
        output.write("]")

    def _print_value(self, output, level, value, breadcrumbs):
        if isinstance(value, dict):
            self._print_dict(output, level, value, breadcrumbs)
        elif isinstance(value, list):
            self._print_list(output, level, value, breadcrumbs)
        else:
            output.write(simplejson.dumps(value))

    def pformat(self, text):
        """Format CloudFormation template text for pretty printing, return as string."""

        self.text = text

        try:
            data = simplejson.loads(self.text)
        except simplejson.scanner.JSONDecodeError as e:
            raise JsonError(e.message)

        if self.copyright:
            add_copyright(data, self.year)

        output = StringIO.StringIO()
        self._print_value(output, 0, data, [])
        return output.getvalue()

def pformat(text, **kwargs):
    """Format CloudFormation template text for pretty printing, return as string."""

    pp = CloudFormationPrettyPrinter(**kwargs)
    return pp.pformat(text)

def main():
    import optparse

    parser = optparse.OptionParser(
            description="Pretty-print a CloudFormation template.",
            usage="usage: %prog [options] [PATH]",
            epilog="WARNING: this has not been tested with non-ASCII character sets.")

    parser.add_option(
            "-s", "--squeeze", action="store_true", default=False,
            help="squeeze output intelligently to use fewer lines")

    parser.add_option(
            "-i", "--indent", metavar="NUM", type=int, default=DEFAULT_INDENT,
            help="indent size (default %d)" % DEFAULT_INDENT)

    parser.add_option(
            "-w", "--width", metavar="NUM", type=int, default=DEFAULT_WIDTH,
            help="desired max width (default %d)" % DEFAULT_WIDTH)

    parser.add_option(
            "-c", "--copyright", action="store_true", default=False,
            help="insert copyright entry into Metadata")

    parser.add_option(
            "-o", "--order", choices=CHOICES_ORDER, default=DEFAULT_ORDER,
            help="specify output order for Resource entries (%s)" % "|".join(CHOICES_ORDER))

    options, args = parser.parse_args()

    if len(args) > 1:
        parser.error("too many arguments")

    text = slurp(args[0] if len(args) > 0 else None)

    try:
        print pformat(
                text,
                squeeze=options.squeeze,
                indent=options.indent,
                width=options.width,
                copyright=options.copyright,
                order=options.order)
    except JsonError as e:
        print >> sys.stderr, "%s: %s" % (os.path.basename(sys.argv[0]), e.message)
        sys.exit(1)

if __name__ == "__main__":
    main()
