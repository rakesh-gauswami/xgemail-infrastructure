#!/usr/bin/env bash
# vim: autoindent expandtab shiftwidth=4 filetype=sh

set -euo pipefail

SCRIPT_DIR=$( dirname "${0}" )
SCRIPT_DIR=$( cd "${SCRIPT_DIR}" && pwd )

PROGRAM="$(basename "${BASH_SOURCE[0]}")"

TERRAFORM_DEFAULT_COMMAND=terraform-1.0

usage() {
    cat <<EOF
Usage: ${PROGRAM} [-h] [-v] DIR COMMAND ...

Run terraform command in DIR, targeting the current PoP environment.

${PROGRAM} will run ${TERRAFORM_DEFAULT_COMMAND} if it is in the PATH, terraform otherwise.

The current PoP environment is determined by the currently active AWS session,
which may be set by environment variables or a credentials file.

Options:
  -h, --help    show this help message and exit
  -v, --verbose print script debug info

COMMAND can be any terraform command.

Examples:
    ${PROGRAM} base_security_groups validate
    ${PROGRAM} deployer_creds init -upgrade
    ${PROGRAM} global_roles output mongoInstanceProfileName
    ${PROGRAM} alb graph | egrep -wv '(provider|var|output)' | dot -Tpng > alb.png
EOF
    exit
}

die() {
    echo "${PROGRAM}: ${1}" 1>&2
    exit "${2-1}"
}

while :; do
    case "${1-}" in
        -h | --help) usage;;
        -v | --verbose) set -x;;
        -?*) die "unknown option: $1";;
        *) break;;
    esac
    shift
done

[[ $# = 0 ]] && die "missing DIR argument"
TERRAFORM_DIR="$1"
shift

[[ -d "${TERRAFORM_DIR}" ]] || die "'${TERRAFORM_DIR}' does not exist or is not a directory"

TERRAFORM_DIR_PATH="$(realpath "${TERRAFORM_DIR}")"

[[ $# = 0 ]] && die "missing CMD argument"
COMMAND="$1"
shift

TERRAFORM=terraform
if which "${TERRAFORM_DEFAULT_COMMAND}" >/dev/null
then
    TERRAFORM="${TERRAFORM_DEFAULT_COMMAND}"
fi

case "${COMMAND}" in
freestyle)
    ;;
*)
    "${TERRAFORM}" "${COMMAND}" -h > /dev/null || die "'${COMMAND}' is not a valid terraform command"
    ;;
esac


# Work in the target directory.

cd "${TERRAFORM_DIR}"

case "${COMMAND}" in
freestyle)
    ;;
*)
    # If there is a leftover .terraform.lock.hcl in TERRAFORM_DIR then terraform
    # will not allow us to upgrade the AWS provider.

    rm -f .terraform.lock.hcl
    ;;
esac

# These commands don't require use to query SSM first.

case "${COMMAND}" in
validate)
    "${TERRAFORM}" init --backend=false --reconfigure

    if [[ -z ${AWS_DEFAULT_REGION+x} ]]
    then
      export AWS_DEFAULT_REGION="us-east-1"
    fi
    "${TERRAFORM}" "${COMMAND}" "${@:+${@}}"
    exit $?
    ;;
fmt|providers|version)
    "${TERRAFORM}" "${COMMAND}" "${@:+${@}}"
    exit $?
    ;;
*)
    ;;
esac

# Now we know where we want to run terraform and what commands we want to run.
# Let's configure the backend based on current AWS credentials.

ssm_get() {
    name="$1"
    aws ssm get-parameter --query Parameter.Value --output text --region us-east-1 --name "$name"
}

aws sts get-caller-identity 1>&2

if [[ -z ${TF_STATE_BUCKET+x} ]]
then
  TF_STATE_BUCKET="$(ssm_get /central/tf/s3-backend-bucket/arn | cut -d: -f6)"
fi

TF_STATE_KEY_PREFIX="terraform/cloud/cloud-infrastructure/terraform/fsc"
TF_STATE_KEY_SUFFIX="$(realpath --relative-to "${SCRIPT_DIR}" "${TERRAFORM_DIR_PATH}")"
TF_STATE_KEY="${TF_STATE_KEY_PREFIX}/${TF_STATE_KEY_SUFFIX}"

if [[ -z ${TF_LOCK_TABLE+x} ]]
then
  TF_LOCK_TABLE="$(ssm_get /central/tf/lock-table/arn | cut -d/ -f2)"
fi

# POP_ACCOUNT_ENV:          account environment type, e.g. "inf"
# POP_ACCOUNT_NAME:         account name, e.g. "stn000cmh"
# POP_ACCOUNT_REGION:       AWS region where the servers will run, e.g. "us-east-2"
# POP_ACCOUNT_TYPE:         account service type, e.g. "station"

POP_ACCOUNT_ENV="$(         ssm_get /central/account/deployment-environment)"
POP_ACCOUNT_NAME="$(        ssm_get /central/account/name)"
POP_ACCOUNT_REGION="$(      ssm_get /central/account/primary-region)"
POP_ACCOUNT_TYPE="$(        ssm_get /central/account/type)"

GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Different directories need different variables.
# Assigning undeclared variables in a tfvars file is deprecated,
# so we'll assign them as environment variables instead.

export TF_VAR_account_name="${POP_ACCOUNT_NAME}"
export TF_VAR_account_type="${POP_ACCOUNT_TYPE}"
export TF_VAR_aws_region="${POP_ACCOUNT_REGION}"
export TF_VAR_deployment_branch="${GIT_BRANCH}"
export TF_VAR_deployment_environment="${POP_ACCOUNT_ENV}"
export TF_VAR_env="${POP_ACCOUNT_ENV}"
export TF_VAR_tag_origin="${TF_STATE_KEY}"

# Terraform plugins cache
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

# Configure AWS.

unset AWS_REGION

export AWS_DEFAULT_REGION="${POP_ACCOUNT_REGION}"

if [[ -z ${AWS_PROFILE+x} ]]
then
  export AWS_PROFILE="${POP_ACCOUNT_NAME}"
fi

if [[ -z ${AWS_SHARED_CREDENTIALS_FILE+x} ]]
then
  export AWS_SHARED_CREDENTIALS_FILE="${HOME}/.aws/credentials"
fi

export AWS_SDK_LOAD_CONFIG=1

# Run terraform.

DEPLOY_PLAN=".terraform/deploy-plan"
DESTROY_PLAN=".terraform/destroy-plan"
TF_BACKEND_VARS_FILE="backend-config.tfvars.json"

function on_exit_trap()
{
  rm -f "${DEPLOY_PLAN}"
  rm -f "${DESTROY_PLAN}"
  rm -f "${TF_BACKEND_VARS_FILE}"
}

trap on_exit_trap EXIT

cat <<EOF >"$TF_BACKEND_VARS_FILE"
{
    "bucket": "${TF_STATE_BUCKET}",
    "key": "${TF_STATE_KEY}",
    "dynamodb_table": "${TF_LOCK_TABLE}",
    "region": "us-east-1"
}
EOF

confirm() {
    echo "$1"
    read -rp "  To confirm please type 'Yes': " yn
    if [[ "${yn}" != Yes ]]; then
        echo "Execution aborted"
        exit 99
    fi
}

tf_init() {
    # Link temporary file descriptor with stdout (saves stdout), redirect stdout to stderr.
    exec {temp_fd}>&1 1>&2

    "${TERRAFORM}" init -backend-config "${TF_BACKEND_VARS_FILE}" -reconfigure "${@:+${@}}"

    # Restore stdout and close temporary file descriptor.
    exec 1>&${temp_fd} {temp_fd}>&-
}

echo "${PROGRAM}: Running '${TERRAFORM} ${COMMAND} ...' in ${TERRAFORM_DIR} for PoP account '${POP_ACCOUNT_NAME}'" 1>&2

case "${COMMAND}" in
    freestyle)
        "${TERRAFORM}" "${@:+${@}}"
        ;;
    init)
        tf_init "${@:+${@}}"
        ;;
    apply)
        tf_init
        "${TERRAFORM}" plan -out "${DEPLOY_PLAN}"
        "${TERRAFORM}" apply "${@:+${@}}" "${DEPLOY_PLAN}"
        ;;
    destroy)
        confirm "Run '${TERRAFORM} ${COMMAND}' in ${TERRAFORM_DIR} for ${POP_ACCOUNT_NAME}?"
        tf_init
        "${TERRAFORM}" plan -out "${DESTROY_PLAN}" -destroy
        "${TERRAFORM}" apply "${@:+${@}}" "${DESTROY_PLAN}"
        ;;
    *)
        tf_init
        "${TERRAFORM}" "${COMMAND}" "${@:+${@}}"
        ;;
esac
