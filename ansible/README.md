### Welcome to the xgemail-infrastructure Ansible Deployment Directory
---

- #####  <i class="fa fa-folder-open fa-fw" style="color:rgb(252,109,38); font-size:.85em" aria-hidden="true"></i> Playbooks Directory - ansible/playbooks
    - #####  <i class="fa fa-folder-open fa-fw" style="color:rgb(252,109,38); font-size:.85em" aria-hidden="true"></i> group_vars - ansible/playbooks/group_vars
        - #####  <i class="fa fa-file-text fa-fw" style="color:rgb(252,109,38); font-size:.85em" aria-hidden="true"></i> [all.yml](ansible/playbooks/group_vars/all.yml)
    - #####  <i class="fa fa-file-text fa-fw" style="color:rgb(252,109,38); font-size:.85em" aria-hidden="true"></i> [find-ami.yml](ansible/playbooks/find-ami.yml)
    - #####  <i class="fa fa-file-text fa-fw" style="color:rgb(252,109,38); font-size:.85em" aria-hidden="true"></i> [build-xgemail-ami.yml](ansible/playbooks/build-xgemail-ami.yml)
    - #####  <i class="fa fa-file-text fa-fw " style="color:rgb(252,109,38); font-size:.85em" aria-hidden="true"></i> [deploy-cloud-email-vpc.yml](ansible/playbooks/deploy-cloud-email-vpc.yml)

- #####  <i class="fa fa-folder-open fa-fw" style="color:rgb(252,109,38); font-size:.85em" aria-hidden="true"></i> Roles Directory - ansible/roles
    - #####  <i class="fa fa-folder-open fa-fw" style="color:rgb(252,109,38); font-size:.85em" aria-hidden="true"></i> common - ansible/roles/common
    
    
    
    
    
    
    
    
    
    




```
ansible-playbook -vvv ./playbooks/build-xgemail-ami.yml --extra-vars="aws_region=${REGION} aws_account=${ACCOUNT} bamboo_plan_key=${bamboo_shortPlanKey} bamboo_branch_name=${bamboo_planRepository_branchName} bamboo_branch_build=${bamboo_buildNumber}"
```
```
ansible-playbook -vvv ./playbooks/deploy-cloud-email-vpc.yml --extra-vars="aws_region=${AWS_REGION} aws_account=${ENVIRONMENT} bamboo_branch_name=${bamboo_planRepository_branchName} bamboo_branch_build=${bamboo_buildNumber}"
```