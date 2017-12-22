#!/usr/bin/env bash

export AWS_ACCESS_KEY_ID=$bamboo_custom_aws_accessKeyId
export AWS_SECRET_ACCESS_KEY=$bamboo_custom_aws_secretAccessKey_password
export AWS_SESSION_TOKEN=$bamboo_custom_aws_sessionToken_password
export AWS_SECURITY_TOKEN=$bamboo_custom_aws_sessionToken_password
export AWS_REGION=$bamboo_REGION

touch aws.txt
echo $AWS_ACCESS_KEY_ID > aws.txt
echo $AWS_SECRET_ACCESS_KEY >> aws.txt
echo $AWS_SESSION_TOKEN >> aws.txt
echo $AWS_REGION >> aws.txt

ansible-doc -l

cd ./ansible
ansible-playbook -vvv ./playbooks/build-xgemail-ami.yml --extra-vars="aws_region=${bamboo_REGION} aws_account=${bamboo_ACCOUNT} bamboo_plan_key=${bamboo_shortPlanKey} bamboo_branch_name=${bamboo_planRepository_branchName} bamboo_branch_build=${bamboo_buildNumber}"