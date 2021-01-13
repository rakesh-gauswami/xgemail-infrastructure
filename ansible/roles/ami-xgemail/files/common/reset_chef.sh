#!/bin/bash
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# common/reset_chef.sh:
#   reset knife.rb and client.rb, delete old nodes, run bare chef-client;
#   used to run chef on a new instance with a different hostname than
#   the host used to configure the parent AMI.

# Fail fast and loud.
set -o xtrace   # Print commands and their arguments as they are executed.
set -o errexit  # Exit immediately if a command exits with a non-zero status.
set -o nounset  # Treat unset variables as an error when substituting.
set -o pipefail # Pipeline status comes from last error, not last command.

if [ "$#" -ne 0 ]; then
    echo "usage: ${1}" 1>&2
    exit 2
fi

for filename in client.rb knife.rb; do
    path="/var/chef/chef-repo/.chef/${filename}"

    /bin/cat <<EOF >"${path}"
cookbook_path   [ '/var/chef/chef-repo/cookbooks' ]
node_path       [ '/var/chef/chef-repo/nodes' ]
EOF

    /bin/chmod 0444 "${path}"
    /bin/chown root:root "${path}"
done

/bin/rm -f /var/chef/chef-repo/nodes/*.*

/usr/bin/chef-client \
    -c /var/chef/chef-repo/.chef/client.rb \
    -l debug -L /var/log/sophos/chef-reset_chef.log \
    -z --no-color
