#!/bin/bash
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2022, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# configure-target.sh:
#   install and configure code for the new ami

# Note: this script should be run inside a chroot jail mounted at the root
#   of the volume that will be snapshot for the root volume of the AMI.

# Fail fast and loud.
set -o xtrace   # Print commands and their arguments as they are executed.
set -o errexit  # Exit immediately if a command exits with a non-zero status.
set -o nounset  # Treat unset variables as an error when substituting.
set -o pipefail # Pipeline status comes from last error, not last command.

# Run in specified directory.
cd "$(/usr/bin/dirname "$0")"

# Remember where we are.
INSTALL_DIR="$(pwd)"
COMMON_DIR="${INSTALL_DIR}/common"

# Load common bash functions.
source "${COMMON_DIR}/sophos_common.sh"

# Report exit status explicitly so we can see it in the log.
onexit() {
    log INFO "${0}: exit status $?"
}
trap onexit EXIT

CHEF_VERSION="${1}"

# Create directory for sophos utilities.
SOPHOS_BIN=/opt/sophos/bin
/bin/mkdir -p "${SOPHOS_BIN}"

# Update the common profile.
SOPHOS_PROFILE=/etc/profile.d/sophos.sh
cat <<'EOF' >"${SOPHOS_PROFILE}"
PATH=${PATH}:/opt/sophos/bin
# Custom login prompt.
# 1. Show current user.
# 2. Show EC2 Xgemail Instance Type, so we can easily select and copy it.
# 3. Show current directory basename.
if [ "$PS1" ]; then
    AWS_INSTANCE_ID=$(curl -fs http://169.254.169.254/latest/meta-data/instance-id)
    REGION=$(curl -fs http://169.254.169.254/latest/meta-data/placement/region)
    APPLICATION=$(aws ec2 describe-tags --region $REGION --filters "Name=resource-id,Values=$AWS_INSTANCE_ID" | jq -r '.Tags[] | select(.Key == "Application").Value')
    PS1="\[\033[01;32m\]\u\[\033[01;33m\]@\[\033[01;35m\]$APPLICATION\[\033[01;36m\]:\[\033[01;34m\]\w\[\033[01;31m\]\$\[\033[0m\] "
fi
EOF

# Update the SSM agent environment.
SSM_AGENT_CONF=/etc/init/amazon-ssm-agent.conf
SSM_AGENT_CONF_TEMP=/tmp/amazon-ssm-agent.conf.$$
awk '
    $1 == "exec" { print "env PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin:/opt/sophos/bin" }
                 { print }
' "$SSM_AGENT_CONF" > "$SSM_AGENT_CONF_TEMP" && mv "$SSM_AGENT_CONF_TEMP" "$SSM_AGENT_CONF"

# Install common utilities.
/bin/cp -r "${COMMON_DIR}"/* "${SOPHOS_BIN}"

# Install latest kernel.
# Requires /proc and /dev be mounted inside this chroot jail, or you'll
# get a "grubby fatal error unable to find a suitable template" message
# and /etc/grub.conf will be left unchanged, so instances will continue
# to boot with the old kernel version.
logtime -- /usr/bin/yum update -y -t -v kernel

# Install all security updates.
logtime -- /usr/bin/yum update -y -t --security

# Install CloudFormation support.
logtime -- /usr/bin/yum update -y -t aws-cfn-bootstrap

# Update aws-amitools-ec2 .
# It provides the ec2-metadata program.
yum update -y -t aws-amitools-ec2

# We assume aws-cli is already installed.
# It depends on boto and botocore but not boto3.

# Install awslogs for mirroring log files to AWS CloudWatch.
logtime -- /usr/bin/yum install -y -t awslogs

# Install python boto3 library.
logtime -- /usr/bin/pip install boto3==1.14.63

# Install epel for amzn2.
amazon-linux-extras install epel -y
yum-config-manager --enable epel

# Downgrade pip to 9.0.3
pip install pip==9.0.3

# Install specific python-daemon module for cfn-hup to work
pip install "python-daemon>=1.5.2,<2.0"

# Install nc for amzn2.
yum install -y -t nc
# Install lnav for amzn2.
yum install -y -t lnav

# Configure S3 to enable KMS/SSE requests.
# Do this after installing boto3 as a quick compatibility test.
logtime -- /usr/bin/aws configure set default.s3.signature_version s3v4


install_chef_repo() {
    local REGION="us-east-1"
    local 3RD_PARTY_REPO="central-3rdparty"
    local CHEF_REPO_HASH=605eeda
    local CHEF_REPO_TGZ=chef-chef-repo-${CHEF_REPO_HASH}.tar.gz
    local CHEF_RPM_TGZ="chef-${CHEF_VERSION}.tar.gz"

    /usr/bin/aws --region ${REGION} s3 cp s3://${3RD_PARTY_REPO}/chef/${CHEF_REPO_TGZ} ${CHEF_REPO_TGZ}
    /bin/tar xzvf ${CHEF_REPO_TGZ}
    /bin/mkdir -p /var/chef/chef-repo/.chef
    /bin/cp -r chef-chef-repo-${CHEF_REPO_HASH}/* /var/chef/chef-repo
    /bin/rm -rf chef-chef-repo-${CHEF_REPO_HASH}
    /bin/chmod +rx /var/chef

    cd /var/chef

    /usr/bin/aws --region ${REGION} s3 cp \
      "s3://${3RD_PARTY_REPO}/chef/${CHEF_RPM_TGZ}" \
      "${CHEF_RPM_TGZ}"

    /bin/tar -xzvf "${CHEF_RPM_TGZ}"
    /bin/rm -rfv "${CHEF_RPM_TGZ}"

    local CHEF_RPM_NAME=$( ls -1 "chef-${CHEF_VERSION}/chef-"*".rpm" )
    /bin/rpm -Uvh --oldpackage --replacepkgs "${CHEF_RPM_NAME}"

    /bin/rm -rfv "chef-${CHEF_VERSION}/"

    /bin/cat <<EOF >/var/chef/chef-repo/.chef/knife.rb
cookbook_path %w[/var/chef/chef-repo/cookbooks]
node_path     %w[/var/chef/chef-repo/nodes]
EOF
    /bin/chmod 0444 /var/chef/chef-repo/.chef/knife.rb

    /bin/cat <<EOF >/var/chef/chef-repo/.chef/client.rb
cookbook_path %w[/var/chef/chef-repo/cookbooks]
node_path     %w[/var/chef/chef-repo/nodes]
EOF
    /bin/chmod 0444 /var/chef/chef-repo/.chef/client.rb

    #logtime -- "${COMMON_DIR}/run_chef.py" -l base_ami.install_chef
}

install_cookbooks() {
    chown -R root:root /tmp/cookbooks
    chmod -R go-w /tmp/cookbooks
    rm -rf /var/chef/chef-repo/cookbooks
    mv -v /tmp/cookbooks /var/chef/chef-repo/
}

create_ohai_hints() {
    # Tell Chef to run the Ohai EC2 plugin.
    # This populates the node object with EC2 metadata, e.g.:
    #   node['ec2']['instance_id']
    #   node['ec2']['local_ipv4']
    #   ...
    # See: http://bdwyertech.net/2015/04/24/chef-ohai-in-aws-ec2-vpc/
    /bin/mkdir -p /etc/chef/ohai/hints
    /bin/touch /etc/chef/ohai/hints/ec2.json
}

logtime -- install_chef_repo
logtime -- install_cookbooks
logtime -- create_ohai_hints
