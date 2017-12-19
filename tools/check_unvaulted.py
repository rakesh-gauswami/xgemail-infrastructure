#!/usr/bin/env python
# vim: autoindent expandtab tabstop=4 softtabstop=4 shiftwidth=4 filetype=python

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

"""
Check files for secrets leaking out instead of being vaulted.
"""

import sys
import os
import re

# Add other indicators of secrets here
SECRET_INDICATORS = ['pass', 'passphrase', 'password', 'secret', 'access_key', 'accesskey']

# Any config lines found with one of these tokens will be exempt from the
# check. Be careful to add only very specific things here. It's better to
# change the config than to change the list here.
EXEMPTIONS = ['/smc_shared_passphrase"',
              'shared-passphrase-config.yml',
              'object: "smc-key-pass"',
              '(MOB_KEYSTORE_ACCESS_KEY)',
              '(MOB_SMC_APP_APNS_DEVELOPMENT_SECRET)',
              '(MOB_SMC_APP_APNS_PRODUCTION_SECRET)',
              '(MOB_PROFILE_SIGNATURE_SECRET)',
              '(MOB_SMC_SERVICES_SECRET)',
              '(MOB_ROOT_CA_SECRET)',
              '(MOB_ROOT_RA_SECRET)',
              '(MOB_KEYSTORE_SECRET_KEY)',
              '(MOB_APPLE_MDM_VENDOR_SECRET)',
              '<your-global-zone-password>']


def is_comment(line):
    """Given a line, check if is a YAML comment."""
    return line.lstrip().startswith('#')


def or_of(terms):
    r"""Construct a part of a regex that matches any of the given terms.
    >>> or_of([])
    ''
    >>> or_of(['a', 'b'])
    '(?:a|b)'
    >>> or_of(['a','b ', ' ',' foo)'])
    '(?:a|b|foo\\))'
    """
    trimmed = [x.strip() for x in terms if x.strip()]
    if not terms:
        return ''
    return '(?:%s)' % '|'.join(re.escape(x) for x in trimmed)


def has_substring(line, expr):
    """Check if the given expression is present in the given line, ignoring
    case, and any leading or trailing whitespace in the line."""
    return re.search(re.compile(expr, re.IGNORECASE), line.strip()) is not None


def is_value_of_one_of(line, keys):
    """Check if one of the given keys has a secret indicator as its value.

    >>> is_value_of_one_of('name: this holds a chipmunk', ['Name', 'description'])
    False
    >>> is_value_of_one_of('name: this holds a secret', ['foo'])
    False
    >>> is_value_of_one_of('name: this holds a chipmunk', ['name'])
    False
    >>> is_value_of_one_of('  name: this holds a secret', ['Name'])
    True
    >>> is_value_of_one_of('  -name: this holds a secret', ['name'])
    True
    >>> is_value_of_one_of('-  name: this holds a secret', ['name'])
    True"""

    return has_substring(line,
                         r'^(?:[-]\s*)?%s\s*:.*%s' % (or_of(keys), or_of(SECRET_INDICATORS)))


def has_secret(line):
    """Check if a line has a secret indicator anywhere in it.

    >>> has_secret('check out this sekret ;)')
    False
    >>> has_secret('desc: nothing to see here')
    False
    >>> has_secret('password: 123')
    True
    >>> has_secret('  name: password')
    True
    >>> has_secret('  # Type your password here. I`ll keep it a secret ')
    True"""

    return has_substring(line, or_of(SECRET_INDICATORS))


def has_secret_placeholder(line):
    """Check if a line holds configuration for a secret but with a
    placeholder. A placeholder must be prefixed with 'tbd' and have a
    preceding space.

    >>> has_secret_placeholder('password: fix_me')
    False
    >>> has_secret_placeholder('name: "stringcheese"')
    False
    >>> has_secret_placeholder(' - password: "123"')
    False
    >>> has_secret_placeholder('  - secret:tbdJmxPassword ')
    False
    >>> has_secret_placeholder('  - secret: tbdJmxPassword ')
    True
    >>> has_secret_placeholder('password: tbdPutSomethingHere;)')
    True"""

    return has_substring(line, '%s:\s+tbd' % or_of(SECRET_INDICATORS))


def has_indicator_in_expression(line):
    """Check if a line has a secret indicator in an expression.

    >>> has_indicator_in_expression('[[ password ]]')
    False
    >>> has_indicator_in_expression('{{ secret}')
    False
    >>> has_indicator_in_expression('  # Type your password {{here}}. I`ll keep it a secret ')
    False
    >>> has_indicator_in_expression('{{secret }} # <-- here')
    True
    >>> has_indicator_in_expression(' - {{secret }}')
    True
    >>> has_indicator_in_expression(' - <% Secret%>')
    True
    >>> has_indicator_in_expression(' - <% ENV["AWS_SECRET_ACCESS_KEY"] %>')
    True
    >>> has_indicator_in_expression('  - name: {{ password }}')
    True"""
    if has_substring(line, r'{{.*(%s)[^}]*}}' % or_of(SECRET_INDICATORS)):
        return True
    return has_substring(line, r'<%%.*(%s)[^}]*%%>' % or_of(SECRET_INDICATORS))


def has_exempted_string(line):
    """Check if a line is exempted by virtue of having a particular token.

    >>> has_exempted_string('password: "foo"')
    False
    >>> has_exempted_string('password: tbdJmxPassword')
    False
    >>> has_exempted_string('    path: "{{ config_aggregation.output_dir }}/{{ role }}/{{ temp }}/smc_shared_passphrase"')
    True
    >>> has_exempted_string('mob_keystore_secret_key: <% ENV["MOB_KEYSTORE_SECRET_KEY"] %>')
    True
    >>> has_exempted_string("your-global-zone-password: '<your-global-zone-password>'")
    True
    """
    for token in EXEMPTIONS:
        if has_substring(line, token):
            return True
    return False


def is_acceptable(line):
    return is_comment(line) or has_secret_placeholder(
            line) or has_indicator_in_expression(
                    line) or is_value_of_one_of(
                            line, ['name']) or has_exempted_string(line)


def check_unvaulted(path, text, err):
    if text is None or text == "":
        print >> err, "%s:0: no content" % path
        return False

    lines = text.splitlines()

    for i, line in enumerate(lines):
        lineno = i + 1
        line = line.lower()
        if has_secret(line) and not is_acceptable(line):
            print >> err, "%s:%d: found secret indicator in unvaulted file" % (path, lineno)
            return False

    return True


def check_file(path):
    with open(path) as fp:
        text = fp.read()
        return check_unvaulted(path, text, sys.stderr)


def check_all():
    failed = False
    for dirpath, dirname, filenames in os.walk(os.getcwd()):
        for fname in filenames:
            fpath = os.path.join(dirpath, fname)
            if os.path.splitext(fname)[1] == '.yml':
                if not check_file(fpath):
                    failed = True
    return failed


def main():
    if '--test' in sys.argv:
        import doctest
        doctest.testmod()
        return

    failed = False

    if not sys.argv[1:]:
        failed = check_all()
    else:
        paths = sys.argv[1:]
        for path in paths:
            if not check_file(path):
                failed = True

    if failed:
        print >>sys.stderr, 'Secret indicators searched: %s' % ', '.join(SECRET_INDICATORS)

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
