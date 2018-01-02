#!/usr/bin/env bash
# vim: autoindent expandtab shiftwidth=4 softtabstop=4 tabstop=4

# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.

# create_base_ami/retrieve-branch-metadata.sh:
#   retrieve Weather Wizard branch metadata for injection into current namespace

if [ $# -ne 1 ]; then
    echo "usage: $0 <output-file>" 1>&2
    exit 2
fi

OUTPUT_FILE="$1"
rm -f "${OUTPUT_FILE}"

# set -o xtrace   # Print commands and their arguments as they are executed.
set -o errexit  # Exit immediately if a command exits with a non-zero status.
set -o nounset  # Treat unset variables as an error when substituting.
set -o pipefail # Pipeline status comes from last error, not last command.

# Retrieve account and region from the branch name.

BAMBOO_BRANCH="${bamboo_shortPlanName}"

IFS='_' read -ra METADATA <<< "$BAMBOO_BRANCH"

if [ ${#METADATA[@]} -lt 4 ]; then
    echo "Branch display name must be of the format:" 1>&2
    echo "branch_account_region_vpcName[_OPTIONAL_PARTS]" 1>&2
    echo "e.g. feature-CPLAT-1234_inf_us-west-2_CloudStation" 1>&2
    echo "e.g. feature-CPLAT-1234_inf_us-west-2_CloudStation_api" 1>&2
    echo "N.B. \"branch\" here will not be used." 1>&2
    exit 2
fi

ACCOUNT="${METADATA[1]}"
REGION="${METADATA[2]}"
VPC_NAME="${METADATA[3]}"
VPC_NAME_LOWER_CASE=$(echo "${VPC_NAME}" | tr '[:upper:]' '[:lower:]')
APPLICATION="${METADATA[4]:-}"

# Determine fallback branch search pattern to use for dependent resources
# (typically AMIs) if they are not available from the repository branch.
# Note that this is a branch pattern; we assume whatever code uses it is
# smart enough to handle multiple matches and do the right thing.

branch="${bamboo_planRepository_branchName}"

if echo "${branch}" | egrep -i -q "^(bugfix|hotfix|release)/"; then
    FALLBACK_BRANCH_PATTERN="release/*"
else
    FALLBACK_BRANCH_PATTERN="develop"
fi

# Is this deployment allowed?
root="$(git rev-parse --show-toplevel)"
permitted=NO
if "${root}/bamboo/check_deployment_branch.py" -b "${branch}" -a "${ACCOUNT}"; then
    permitted=YES
fi

# We want the deployment to fail if it is not allowed, but exiting
# with a non-zero status from this program may not be enough to cause
# the failure.  There are a couple ways things could go wrong:
#
# First, this program may be called in a UNIX pipeline that discards
# the exit code of all but the last program in the pipe.  If the shell
# option pipefail is not set then the pipeline can succeed even if one
# of the programs in the pipeline fails.
#
# Second, another program may be called after this one, for example
# to cat the output file.  If the shell option errexit is not set then
# the fact that this program fails will not preclude execution of a
# subsequent program that masks this program's failure.
#
# To guard against the exit code being ignored we will modify the
# variable assignment output to make it unusable when deployment is
# not allowed.

leader=
header=
if [ "${permitted}" = NO ]; then
    leader="# "
    header="Deployment of branch '${branch}' to account '${ACCOUNT}' is NOT permitted."
    echo "${header}" 1>&2
fi

# Save generated variables, modified to fail if deployment is not permitted.

if [ -n "${header}" ]; then
    echo "${header}" | tee -a "${OUTPUT_FILE}"
fi

cat <<EOF | sed -e "s|^|${leader}|" | tee -a "${OUTPUT_FILE}"
ACCOUNT=${ACCOUNT}
REGION=${REGION}
VPC_NAME=${VPC_NAME}
VPC_NAME_LOWER_CASE=${VPC_NAME_LOWER_CASE}
FALLBACK_BRANCH_PATTERN=${FALLBACK_BRANCH_PATTERN}
APPLICATION=${APPLICATION}
EOF


# Don't forget to fail :)

if [ "${permitted}" = NO ]; then
    exit 1
fi
