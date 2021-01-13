#!/bin/bash
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# common/sophos_common.sh:
#   common bash functions, use bash "source" command to import

# Log something with a timestamp.
log() {
    echo "$(date +'%F %T')" "$*"
}


# Record time taken by various commands.
logtime() {
    local operation
    local start_time
    local end_time
    local seconds

    operation="$1"
    shift

    if [ "${operation}" = "--" ]; then
        operation="$*"
    fi

    log INFO ENTER "${operation}"

    start_time="$(date +%s)"

    $*

    end_time="$(date +%s)"
    seconds="$(expr "${end_time}" - "${start_time}" || true)"

    log INFO LEAVE "${operation} took ${seconds} seconds"
}
