#!/bin/bash
#
# Copyright 2016, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#
# terminate-flagged-instances.sh script:
#   Executes terminate-instance.py script on Xgemail submit and delivery nodes
#   that have been tagged with CloudEmail:ShouldTerminate=true in all regions.
#
#   Expects script file to live somewhere on hopper
#

set -eu

# print failure message
print_failure()
{
  echo -e -n "[FAILURE] "
}

# print success message
print_success()
{
  echo -e -n "[SUCCESS] "
}

# print script usage
function print_usage ( )
{
  echo "Usage: ${0} /path/to/terminate-instance.py"
}

if (( $# > 1 || $# == 0 ))
then
  exec 1>&2
  print_usage
  exit 1
fi

PATH_TO_TERMINATE_SCRIPT="${1}"

if [[ ! -f "${PATH_TO_TERMINATE_SCRIPT}" ]]
then
  exec 1>&2
  echo "Invalid path to script: ${PATH_TO_TERMINATE_SCRIPT}"
  print_usage
  exit 1
fi

TERMINATE_SCRIPT_FILENAME=$( basename "${PATH_TO_TERMINATE_SCRIPT}" )

SUCCESS_INSTANCES=()
FAILED_INSTANCES=()

eval $(/usr/bin/keychain --eval --agents ssh -Q --quiet)

for region in \
  'us-west-2' \
  'us-east-2' \
  'eu-west-1' \
  'eu-central-1'
do

  # retrieve all instances that are tagged as 'ShouldTerminate' and
  # are currently in the running state (instance-state-code=16)
  instance_ids=$(
    aws ec2 --region="${region}" \
              describe-instances \
              --filters Name=tag:CloudEmail:ShouldTerminate,Values=true \
                    Name=instance-state-code,Values=16 \
              --query 'Reservations[*].Instances[*].[InstanceId]' \
              --output text
  )

  # skip the region if no instance ids are tagged for termination
  [ -z "${instance_ids}" ] \
    && echo "Skipping region ${region} - no applicable instances found" \
    && continue

  for instance_id in ${instance_ids}
  do
    echo "Connecting to instance ${region}:${instance_id}"

    exit_code=0
    cloud scp "${PATH_TO_TERMINATE_SCRIPT}" "${instance_id}:~/" || exit_code=$?

    if [ ${exit_code} != 0 ]
    then
      FAILED_INSTANCES+=("${region}:${instance_id}")
      continue
    fi

    ssh_command=""
    ssh_command+="set -eu;"
    ssh_command+="echo \"Running on ${instance_id}\";"
    ssh_command+="chmod -c 755 './${TERMINATE_SCRIPT_FILENAME}';"
    ssh_command+="sudo './${TERMINATE_SCRIPT_FILENAME}';"

    cloud ssh "${instance_id}" "${ssh_command}" || exit_code=$?

    if [ ${exit_code} != 0 ]
    then
      FAILED_INSTANCES+=("${region}:${instance_id}")
    else
      SUCCESS_INSTANCES+=("${region}:${instance_id}")
    fi
  done
done

echo
echo "Summary:"
echo "------------------"
if [ ${#SUCCESS_INSTANCES[@]} -gt 0 ]
  then
  for instance in "${SUCCESS_INSTANCES[@]}"
  do
    print_success
    echo " ${instance}"
  done
fi

if [ ${#FAILED_INSTANCES[@]} -gt 0 ]
then
  for instance in "${FAILED_INSTANCES[@]}"
  do
    print_failure
    echo " ${instance}"
  done

  echo
  echo "Execution of this script failed on some instances," \
       "most likely because the instances are still holding email."
  echo "Running this script again will retry the failed instances."
fi
