#!/usr/bin/env bash
# vim: autoindent expandtab shiftwidth=4 filetype=sh

set -euo pipefail

SCRIPT_DIR=$( dirname "${0}" )
SCRIPT_DIR=$( cd "${SCRIPT_DIR}" && pwd )

PROGRAM="$(basename "${BASH_SOURCE[0]}")"

if [[ $# -lt 3 ]]; then
  echo "Usage: $PROGRAM <KEY> <SECRET> <DESCRIPTION>"
  exit 1
fi

SECRET_NAME="$1"
SECRET_STRING="$2"
DESCRIPTION="$3"

# to_entries produces lower-case key, value array
# AWS, of course, requires Capitalized Key, Value array
# hence the manipulation after the to_entrie
TAGS=$(
  jq --null-input \
    --arg name "${SECRET_NAME}" \
  '
  {
    Application: "xgemail-infrastructure",
    BusinessUnit: "MSG",
    Name: $name,
    OwnerEmail: "SophosMailOps@sophos.com",
    Project: "xgemail-infrastructure"
  }
  |
  to_entries
  |
  .[] |= with_entries(
    .key |= (split("") | .[0] |= ascii_upcase | join(""))
  )
  '
)

ssm_get() {
    name="$1"
    aws ssm get-parameter --query Parameter.Value --output text --region us-east-1 --name "$name"
}

export AWS_DEFAULT_REGION="$(ssm_get /central/account/primary-region)"

SECRET_INFO=$(
  aws secretsmanager list-secret-version-ids \
    --output json \
    --secret-id "${SECRET_NAME}" 2>/dev/null || true
)

if [[ -z "${SECRET_INFO}" ]]
then
  echo "Creating brand new secret with name <${SECRET_NAME}>"

  aws secretsmanager create-secret \
    --name "${SECRET_NAME}" \
    --description "${DESCRIPTION}" \
    --secret-string "${SECRET_STRING}" \
    --tags "${TAGS}"
else

  SECRET_ARN=$(
    echo "${SECRET_INFO}" | jq -r '.ARN'
  )

  echo "Updating existing secret <${SECRET_ARN}>"

  aws secretsmanager update-secret \
    --secret-id "${SECRET_ARN}" \
    --description "${DESCRIPTION}" \
    --secret-string "${SECRET_STRING}"

  aws secretsmanager tag-resource \
    --secret-id "${SECRET_ARN}" \
    --tags "${TAGS}"
fi
