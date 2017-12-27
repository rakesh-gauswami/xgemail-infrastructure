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
ansible-playbook --version
#cd ./ansible
#ansible-playbook -vvv ./playbooks/build-xgemail-ami.yml --extra-vars="aws_region=${bamboo_REGION} aws_account=${bamboo_ACCOUNT} bamboo_plan_key=${bamboo_shortPlanKey} bamboo_branch_name=${bamboo_planRepository_branchName} bamboo_branch_build=${bamboo_buildNumber}"

docker run --entrypoint="ansible-playbook" \
    -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
    -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" \
    -e "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" \
    -e "AMI_BUILD_TIMEOUT_MINUTES=$bamboo_AMI_BUILD_TIMEOUT_MINUTES" \
    -e "AMI_PARENT_ALTERNATE_BUGFIX_BRANCH=$bamboo_AMI_PARENT_ALTERNATE_BUGFIX_BRANCH" \
    -e "AMI_PARENT_ALTERNATE_FEATURE_BRANCH=$bamboo_AMI_PARENT_ALTERNATE_FEATURE_BRANCH" \
    -e "AMI_PARENT_DESCRIPTION=$bamboo_AMI_PARENT_DESCRIPTION" \
    -e "AMI_TYPE=$bamboo_AMI_TYPE" \
    -e "AES_KEY=$bamboo_aeskey" \
    -e "CONNECTOR_ENV=$bamboo_CONNECTOR_ENV" \
    -e "COPYREGIONS=$bamboo_COPYREGIONS" \
    -e "LAUNCHPERMISSIONS=$bamboo_LAUNCHPERMISSIONS" \
    -e "REGION=$bamboo_REGION" \
    -e "VPC_SECURITYGROUPID=$bamboo_VPC_SECURITYGROUPID" \
    -e "VPC_SUBNETID=$bamboo_VPC_SUBNETID" \
    -e "blockDeviceMappingsXvdf=$bamboo_blockDeviceMappingsXvdf" \
    --volume="$PWD:/work" \
    --workdir="/work/ansible" \
    "registry.sophos-tools.com/sophos-ansible:2.4.0.0-2" \
    -vvv ./playbooks/build-xgemail-ami.yml \
    --extra-vars="aws_account=${bamboo_ACCOUNT} \
                  aws_region=${bamboo_REGION} \
                  bamboo_branch_name=${bamboo_planRepository_branchName} \
                  bamboo_plan_key=${bamboo_shortPlanKey} \
                  bamboo_build_key=${bamboo_buildKey} \
                  bamboo_build_result_key=${bamboo_buildResultKey} \
                  bamboo_build_number=${bamboo_buildNumber}"