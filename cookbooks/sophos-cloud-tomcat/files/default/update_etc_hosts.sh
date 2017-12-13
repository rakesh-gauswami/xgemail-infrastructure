#!/bin/bash

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

PROGRAM="$(basename "$0")"

# Print message to stderr and exit.
die() {
    echo "${PROGRAM}:" "$@" 1>&2
    exit 1
}

# Print message to stderr.
msg() {
    echo "${PROGRAM}:" "$@" 1>&2
}

# Get AWS metadata.
get_aws_metadata() {
    key="$1"

    result=$(curl -s -S "http://169.254.169.254/latest/meta-data/${key}")

    if [ -z "$result" ]; then
        die "cannot find '$key' in file '$path'"
    else
        echo "$result"
    fi
}

# Extract address list from properties file with given key.
get_address_list() {
    path="$1"
    key="$2"

    result=$(grep "^${key} *=" "${path}" | cut -d= -f2 | awk '{print $NF}')

    if [ -z "$result" ]; then
        die "cannot find '$key' in file '$path'"
    else
        echo "$result"
    fi
}

# Extract hostnames from address list by stripping of port suffixes.
get_address_list_hostnames() {
    list="$1"

    # Convert commas to spaces using tr.
    # Convert spaces to newlines using fmt.
    # Remove port suffix using cut.
    # Filter out pure IP addresses with grep.
    result=$(echo "$list" | tr , ' ' | fmt -1 | cut -d: -f1 | grep '[a-zA-Z]')

    if [ -z "$result" ]; then
        die "cannot find any hostnames in address list '$list'"
    else
        echo "$result"
    fi
}

# Lookup IP address(es) for hostname.
get_ip_addresses() {
    hostname="$1"

    output=$(/usr/bin/host "$hostname")
    status=$?

    if [ "$status" != 0 ]; then
        msg "$output"
        return 1
    else
        echo "$output" | fmt -1 | grep '^[0-9][0-9\.]*[0-9]$'
    fi
}

# Describe the instance with the given private IP address to get its public IP address.
aws_get_public_ip_from_private_ip() {
    region="$1"
    private_ip="$2"

    filter="Name=private-ip-address,Values=${private_ip}"
    query='Reservations[0].Instances[0].PublicIpAddress'
    output=$(aws ec2 describe-instances --region "$region" --filter "$filter" --query "$query")
    status=$?

    if [ -z "$output" ]; then
        msg "cannot find instance with private ip '$private_ip'"
        return 1
    elif [ "$status" != 0 ]; then
        msg "$output"
        return 1
    else
        echo "$output" | tr -d '"'
    fi
}

# Update file from working copy, saving original and previous versions.
update_file() {
    target="$1"
    source="$2"

    if cmp -s "$source" "$target"; then
        return 0
    fi

    original="${target}.orig"
    previous="${target}.prev"

    # Preserve the ORIGINAL.
    if [ ! -e "$original" ]; then
        if ! cp "$target" "$original"; then
            die "cannot preserve original copy of ${target}"
        fi
    fi

    # Backup the CURRENT file.
    if ! cp -f "$target" "$previous"; then
        die "cannot preserve original copy of ${target}"
    fi

    # Install the NEW file.
    if ! cp -f "$source" "$target"; then
        die "cannot install new ${target}"
    fi
}


BOOTSTRAP_PROPERTIES=/usr/local/etc/sophos/bootstrap.properties
if [ ! -r "$BOOTSTRAP_PROPERTIES" ]; then
    die "cannot read file '${BOOTSTRAP_PROPERTIES}'"
fi

MONGO_ADDRESSES=$(get_address_list "$BOOTSTRAP_PROPERTIES" "mongoClient.addresses")
MONGO_HOSTNAMES=$(get_address_list_hostnames "$MONGO_ADDRESSES")

REDIS_ADDRESSES=$(get_address_list "$BOOTSTRAP_PROPERTIES" "redisPool.addresses")
REDIS_HOSTNAMES=$(get_address_list_hostnames "$REDIS_ADDRESSES")

WORKING_COPY="/tmp/${PROGRAM}.$$"
if ! cp /etc/hosts "$WORKING_COPY"; then
    die "cannot create working copy of /etc/hosts"
fi

trap 'rm -f ${WORKING_COPY}' EXIT

REGION=$(get_aws_metadata placement/availability-zone | sed -e 's/[a-z]$//')
for hostname in $MONGO_HOSTNAMES $REDIS_HOSTNAMES; do
    # Remove any prior entries for hostname in the working copy.
    /bin/sed -i "/ ${hostname}/d" "$WORKING_COPY"

    # Append new entries to the working copy.
    for private_ip in $(get_ip_addresses "$hostname"); do
        if public_ip=$(aws_get_public_ip_from_private_ip "$REGION" "$private_ip"); then
            printf '%-15s %s\n' "$public_ip" "$hostname" >> "$WORKING_COPY"
        fi
    done
done

update_file /etc/hosts "$WORKING_COPY"

