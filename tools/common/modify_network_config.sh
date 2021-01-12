#!/bin/bash
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# common/modify_network_config.sh:
#   update network configuration to support DNS lookups within the AWS region


aws_metadata() {
    wget -q -O- "http://169.254.169.254/latest/meta-data/$1"
}

private_ip="$(aws_metadata local-ipv4)"

host_name="$(aws_metadata local-hostname)"

region="$(aws_metadata placement/availability-zone | sed -e 's/[a-z]$//')"

domain_name="${region}.compute.internal"
if [ "${region}" = "us-east-1" ]; then
    domain_name=ec2.internal
fi

# Note: the extra blank lines appended to the various configuration files
# is there to handle the case where the final newline might be missing
# from the file.

# Configure local host mapping.
cat <<EOF >>/etc/hosts

127.0.0.1 ${host_name} localhost
${private_ip} ${host_name}
EOF

# Configure DHCP.
cat <<EOF >>/etc/dhcp/dhclient.conf

supersede domain-name "${domain_name}";
EOF

# Configure DNS resolution.
cat <<EOF >>/etc/resolv.conf

${domain_name}
EOF
