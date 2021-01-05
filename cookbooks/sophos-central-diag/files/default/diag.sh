#!/bin/sh
# vim: autoindent expandtab shiftwidth=4 filetype=sh

# Copyright 2018, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# Execute and print output from all commands found under $DIAG_SCRIPT_ROOT.
# Fail if any command fails, but execute ALL commands.

# Execute scripts found under this directory:
DIAG_SCRIPT_ROOT=/opt/sophos/etc/diag.d

# No complicated options, but always support -h and --help.
if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo "usage: $(basename "$0")"
    echo
    echo "Execute and print output from all executable scripts found under"
    echo "${DIAG_SCRIPT_ROOT}"
    echo
    echo "Note: this command should be run as root."
    exit 0
fi

# Store script output in this file:
DIAG_OUTPUT_FILE=/tmp/diag.$$

# Ensure the script output file is deleted when we exit:
trap 'rm -f ${DIAG_OUTPUT_FILE}' EXIT

# Remember whether or not any scripts failed.
ANY_FAILED=0

echo "Running diagnostic scripts found under ${DIAG_SCRIPT_ROOT}:"
echo

for DIAG_SCRIPT in $(find "${DIAG_SCRIPT_ROOT}" -type f | sort); do
    test -x "${DIAG_SCRIPT}" || continue

    echo -n "${DIAG_SCRIPT} ... "

    "${DIAG_SCRIPT}" > "${DIAG_OUTPUT_FILE}" 2>&1

    if [ $? = 0 ]; then
        echo PASS
    else
        echo FAIL
        ANY_FAILED=1
    fi

    sed -e "s/^/> /" "${DIAG_OUTPUT_FILE}"
    echo
done

# Summarize.
if [ "${ANY_FAILED}" = 0 ]; then
    echo "All diagnostic checks succeeded."
    exit 0
else
    echo "One or more diagnostic checks failed."
    exit 1
fi
