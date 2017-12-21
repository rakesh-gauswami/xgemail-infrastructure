ansible-playbook -vvv ./playbooks/deploy-cloud-email-vpc.yml --extra-vars="aws_region=${AWS_REGION} aws_account=${ENVIRONMENT} bamboo_branch_name=${bamboo_planRepository_branchName} bamboo_branch_build=${bamboo_buildNumber}"



ansible-playbook -vvv ./playbooks/build-xgemail-ami.yml --extra-vars="aws_region=${REGION} aws_account=${ACCOUNT} bamboo_plan_key=${bamboo_shortPlanKey} bamboo_branch_name=${bamboo_planRepository_branchName} bamboo_branch_build=${bamboo_buildNumber}"