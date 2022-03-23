#!/bin/bash
#
# This script provides convenient functions to start and operate xgemail
# sandbox
#
# Copyright: Copyright (c) 1997-2021. All rights reserved.
# Company: Sophos Limited or one of its affiliates.

: 'Set XGEMAIL_HOME environment variable
'
function set_home {
    # Set XGEMAIL_HOME environment variable
    echo -e "Setting environment variable <XGEMAIL_HOME> to <~/g/email/>"
    echo -e "${YELLOW} NOTE: XGEMAIL_HOME points to the directory above which xgemail-infrastructure and xgemail repo live locally ${NC}"
    export XGEMAIL_HOME="${HOME}/g/email/"

    if [ ! $? -eq 0 ]; then
        echo -e "${RED} Unable to set XGEMAIL_HOME environment variable ${NC}"
        exit 1
    else
        echo -e "${GREEN} XGEMAIL_HOME environment successfully set to ${XGEMAIL_HOME} ${NC}"
    fi
}
set_home

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'

xgemail_infrastructure_location="${XGEMAIL_HOME}xgemail-infrastructure/"
orchestrator_location="${xgemail_infrastructure_location}orchestrator/"

base_compose="docker-compose-base.yml"
inbound_compose="docker-compose-inbound.yml"
outbound_compose="docker-compose-outbound.yml"

nova_bootstrap_file="${HOME}/g/nova/appserver/config/bootstrap.properties.d/00_bootstrap.properties"
mail_bootstrap_file="${orchestrator_location}sophos_cloud_tomcat_bootstrap.properties"
nova_bootstrap_file_original_copy="${HOME}/g/nova/appserver/config/bootstrap_copy.properties"

nova_docker_compose_single="${HOME}/g/nova/docker-compose.yml"
xgemail_replacement_nova_compose="${orchestrator_location}docker-compose-nova-single.yml"
nova_docker_compose_original_copy="${HOME}/g/nova/docker-compose-single_copy.yml"

nova_env_file="${HOME}/g/nova/.env"
nova_env_file_original_copy="${HOME}/g/nova/.env_original_copy"
mail_env_file="${orchestrator_location}environment"

sasi_service_image="283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/sasi-service:latest"
sasi_docker_image="283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/sasi-daemon:latest"

jilter_version="current"

email_tomcat_url="localhost:9898"
nova_tomcat_url="appserver.sandbox.sophos:8080"

possible_clean_up_files=()


: 'This function has to run before starting nova. It carries out various setup steps:
1. replaces docker-compose-single file of nova
2. adds to the bootstrap file for deploying wars in nova hub
'
function initialize {
    echo -e "${YELLOW} Running set up steps ${NC}"
    echo -e "${YELLOW} NOTE: This should be run each time before starting NOVA ${NC}"

   #override nova appserver bootstrap file
    if [ ! -f ${nova_bootstrap_file} ]; then
        echo -e "${RED} ${nova_bootstrap_file} could not be found. Ensure it exists at the right location ${NC}"
        exit 1
    fi

    if [ ! -f ${nova_bootstrap_file_original_copy} ]; then
        cp ${nova_bootstrap_file} ${nova_bootstrap_file_original_copy}
    fi

    #create new bootstrap file by concatenating it with existing bootstrap file in nova
    create_mail_bootstrap

    override_files ${nova_bootstrap_file} ${mail_bootstrap_file}

    #override nova docker-compose-single.yml file
    if [ ! -f ${nova_docker_compose_single} ]; then
        echo -e "${RED} ${nova_docker_compose_single} could not be found. Ensure it exists at the right location ${NC}"
        exit 1
    fi

    if [ ! -f ${nova_docker_compose_original_copy} ]; then
        cp ${nova_docker_compose_single} ${nova_docker_compose_original_copy}
    fi

    override_files ${nova_docker_compose_single} ${xgemail_replacement_nova_compose}

    #Override nova env file
    if [ ! -f ${nova_env_file} ]; then
        echo -e "${RED} ${nova_env_file} could not be found. Ensure it exists at the right location ${NC}"
        exit 1
    fi

    if [ ! -f ${nova_env_file_original_copy} ]; then
        cp ${nova_env_file} ${nova_env_file_original_copy}
    fi

    override_files ${nova_env_file} ${mail_env_file}

    echo -e "${GREEN} Initialization Completed Successfully ${NC}"
}

: 'This function creates, starts and provisions the base containers required for
inbound mail flow. These containers can be found in docker-compose-inbound.yml
and docker-compose-base.yml
'
function deploy_inbound {
    initialize
    check_nova_up
    check_login_to_aws
    download_libspf_package

    echo -e "${YELLOW} user selected inbound ${NC}"
    echo -e "${YELLOW} Services needed for inbound mail-flow will be started ${NC}"
    echo ""

    check_sasi ${sasi_service_image} ${sasi_docker_image}

    create_mail_bootstrap

    docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${inbound_compose} up -d

    deploy_wars "mail-service" "false" "mail" "mailinbound"

    provision_localstack

    provision_postfix "postfix-is" "postfix-cd"

    deploy_jilter inbound

    check_tomcat_startup ${email_tomcat_url} "mail" "mailinbound"
}

: 'This function creates, starts and provisions the base containers required for
outbound mail flow. These containers can be found in docker-compose-outbound.yml
and docker-compose-base.yml
'
function deploy_outbound {
    initialize
    check_nova_up
    check_login_to_aws
    download_libspf_package

    check_sasi ${sasi_service_image} ${sasi_docker_image}

    echo -e "${YELLOW} user selected outbound ${NC}"
    echo -e "${YELLOW} Services needed for outbound mail-flow will be started ${NC}"
    echo ""

    create_mail_bootstrap

    docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${outbound_compose} up -d

    deploy_wars "mail-service" "false" "mail" "mailoutbound"

    provision_localstack

    provision_postfix "postfix-cs" "postfix-id"

    deploy_jilter outbound

    check_tomcat_startup ${email_tomcat_url} "mail" "mailoutbound"
}

: 'This function creates, starts and provisions the base containers required for
both inbound and outbound mail flow. These containers can be found in docker-compose-inbound.yml,
docker-compose-outbound.yml and docker-compose-base.yml
'
function deploy_all {
    initialize
    check_login_to_aws
    check_nova_up
    check_login_to_aws

    echo -e "${YELLOW} user selected all ${NC}"
    echo -e "${YELLOW} Services needed for both inbound and outbound mail-flow will be started ${NC}"
    echo ""

    create_mail_bootstrap

    docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${inbound_compose} -f ${orchestrator_location}${outbound_compose} up -d

    deploy_wars "mail-service" "false" "mail" "mailinbound" "mailoutbound"

    provision_localstack

    provision_postfix "postfix-cs" "postfix-id" "postfix-is" "postfix-cd"

    deploy_jilter all

    check_tomcat_startup ${email_tomcat_url} "mail" "mailoutbound" "mailinbound"
}

: 'This function runs the script to provision postfix instances.
It takes as an input the postfix instances to be provisioned
'
function provision_postfix {
    if [ "$#" -eq 0 ]; then
        echo -e "${RED} No postfix instances specified for provisioning ${NC}"
        exit 1
    fi

    for service in "$@"; do
        check_service_up ${service}
        echo -e "${GREEN} provisioning ${service} started ${NC}"
        docker exec ${service} /opt/run.sh
        if [ $? -eq 0 ]; then
            echo -e "${GREEN} provisioning ${service} successfully completed ${NC}"
        else
            echo -e "${RED} provisioning ${service} failed ${NC}"
            exit 1
        fi
    done
}

: 'This function provisions localstack.
It runs the script to create all the necessary queues, sns topics and s3 buckets
'
function provision_localstack {
    check_service_up localstack
    echo -e "${GREEN} provisioning localstack started ${NC}"
    bash ${orchestrator_location}do_it.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN} provisioning localstack successfully completed ${NC}"
    else
        echo -e "${RED} provisioning localstack failed ${NC}"
        exit 1
    fi
}

: 'This function provisions jilter based on the jilter instance specified
'
function provision_jilter {
    check_service_up $1

    echo "Provisioning $1"

    docker exec $1 sh -c '/opt/run.sh'

    #At the time of writing this script, docker exec had a bug that results in the exit
    #code of a command being run in a container not being properly returned
    #Hence we don't check the exit code here
    echo -e "${YELLOW} $1 Provisioning completed. ${NC}"
}

: 'This function retrieves the specified war files in the current local sophos-cloud directory
It then copies them into a folder from which they are hot deployed into a running tomcat docker instance.
'
function deploy_wars {
    if [ "$#" -eq 0 ]; then
        echo -e "${RED} No wars or services specified for deployment ${NC}"
        exit 1
    fi

    service_name="$1"
    shift

    hot_deploy="$1"
    shift

    echo -e "${GREEN} Starting to deploy '$@' ${NC}"
    pushd ${HOME}/g/cloud/sophos-cloud >/dev/null 2>&1
    raw_branch=$(git rev-parse --abbrev-ref HEAD)
    branch=$(echo $raw_branch | tr / _ | tr - _)

    services_count="$#"
    services_found=()
    warfiles_found=()
    #look for war files
    for war in "$@"; do
        local spath="./${war}-services/build/libs/${war}-services-${branch}-LOCAL.war"
        if [ -e "$spath" ]; then
            warfiles_found+=("$spath")
            services_found+=("$war")
        fi
    done

    war_count=${#warfiles_found[@]}
    if [[ $war_count -ne $services_count ]]; then
        echo "found services: [${services_found[@]}] , expected: [$@]"
        echo -e "${RED}All war files were not available in the current branch"
        echo -e "You may not have assembled the necessary wars. Please ensure all war files are available"
        comma_seperated_services=$(join , "$@")
        echo -e "Run './gradlew {"$comma_seperated_services"}-services:clean {"$comma_seperated_services"}-services:assemble' in the sophos cloud repo ${NC}"
        exit 1
    else
        echo "War files have been indexed"
    fi

    war_file_location="${HOME}/.xgemail_sandbox/wars"

    mkdir -p ${war_file_location}

    if [ ! $? -eq 0 ]; then
        echo -e "${RED} Failed to create ${war_file_location} ${NC}"
        exit 1
    fi
    tomcat_webapps_loc="/usr/local/tomcat/webapps/"

    check_service_up ${service_name}

    #copy war files into .xgemail_sandbox/wars and hot deploy them into tomcat container
    for file in "${warfiles_found[@]}" ; do
        filename=$(echo "$file" | xargs -n 1 basename)
        prefix=$(echo "$filename" | awk -F"-" '{print $1}')
        newfile=$(echo "$prefix"-services.war)
        newfile_location="${war_file_location}/${newfile}"
        rsync -a --progress "${file}" "${newfile_location}"
        if [ ! $? -eq 0 ]; then
            echo -e "${RED} Failed to copy over ${file} to ${newfile_location} ${NC}"
            continue
        fi
        destination_file_in_container="${tomcat_webapps_loc}${newfile}"

        #remove if the war file is already present
        docker exec ${service_name} rm -f ${destination_file_in_container} >/dev/null

        # wait for a few seconds for undeploy to happen if doing a hot deploy
        #TODO: refactor this by adding a function that checks to see if the undeploy is completed
        #rather than just wait. Waiting works for now
        if [ ${hot_deploy} = "true" ];then
          echo "Undeploying ${prefix}"
          sleep 30
        fi

        echo "Copying WAR file ${newfile_location} into Tomcat for deployment"
        docker cp "${newfile_location}" "${service_name}:${destination_file_in_container}"
        if [ ! $? -eq 0 ]; then
            echo -e "${RED} Failed to copy ${newfile_location} into Tomcat containers ${NC}"
            echo "try recopying the war files into the tomcat container using 'docker cp <source> container_name:<destination>'"
            continue
        fi
        newfiles+="|$newfile|"
    done

    popd >/dev/null

    echo -e "${GREEN} successfully copied ${newfiles} into Tomcat ${NC}"
    newfiles=()
}

: 'This function deploys jilter tar files by copying them into a directory from
which they are mounted into jilter instances
'
function deploy_jilter()
{
    build_policy_storage_for_jilter

    jilter_location="${XGEMAIL_HOME}xgemail/"

    sandbox_inbound_jilter_tar_location="${HOME}/.xgemail_sandbox/jilter/inbound/"
    sandbox_outbound_jilter_tar_location="${HOME}/.xgemail_sandbox/jilter/outbound/"

    sudo chown -R svc_msguser:svc_msguser ${HOME}/.xgemail_sandbox/jilter/

    jilter_inbound_build_location="${jilter_location}xgemail-jilter-inbound/build/distributions/"
    jilter_inbound_build_name="xgemail-jilter-inbound-${jilter_version}.tar"

    jilter_mf_inbound_build_location="${jilter_location}xgemail-jilter-mf-inbound/build/distributions/"
    jilter_mf_inbound_build_name="xgemail-jilter-mf-inbound-${jilter_version}.tar"

    jilter_mf_outbound_build_location="${jilter_location}xgemail-jilter-mf-outbound/build/distributions/"
    jilter_mf_outbound_build_name="xgemail-jilter-mf-outbound-${jilter_version}.tar"

    jilter_outbound_build_location="${jilter_location}xgemail-jilter-outbound/build/distributions/"
    jilter_outbound_build_name="xgemail-jilter-outbound-${jilter_version}.tar"

    case $1 in
        inbound)
            check_service_up jilter-inbound
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_inbound_build_location} ${jilter_inbound_build_name}

            provision_jilter jilter-inbound
        ;;
        outbound)
            check_service_up jilter-outbound
            deploy_jilter_helper ${sandbox_outbound_jilter_tar_location} ${jilter_outbound_build_location} ${jilter_outbound_build_name}
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_inbound_build_location} ${jilter_inbound_build_name}

            provision_jilter jilter-outbound
        ;;
        mfinbound)
            check_service_up jilter-mf-inbound
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_mf_inbound_build_location} ${jilter_mf_inbound_build_name}

            provision_jilter jilter-mf-inbound
        ;;
        mfoutbound)
            check_service_up jilter-mf-outbound
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_mf_outbound_build_location} ${jilter_mf_outbound_build_name}

            provision_jilter jilter-mf-outbound
        ;;
        all)
            check_service_up jilter-inbound
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_inbound_build_location} ${jilter_inbound_build_name}

            provision_jilter jilter-inbound

            check_service_up jilter-mf-inbound
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_mf_inbound_build_location} ${jilter_mf_inbound_build_name}

            provision_jilter jilter-mf-inbound

            check_service_up jilter-mf-outbound
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_mf_outbound_build_location} ${jilter_mf_outbound_build_name}

            provision_jilter jilter-mf-outbound

            check_service_up jilter-outbound
            deploy_jilter_helper ${sandbox_outbound_jilter_tar_location} ${jilter_outbound_build_location} ${jilter_outbound_build_name}

            provision_jilter jilter-outbound
        ;;
        *)
        clean_up_files
        exit 1
        ;;
    esac
}

: 'This function is a helper to deploy_jilter that copies jilter files into a directory
and mounts them into a running jilter docker instance
'
function deploy_jilter_helper()
{
    if [ ! $# -eq 3 ]; then
        echo "${RED} This function needs to take in 3 inputs ${NC}"
        exit 1
    fi

    sandbox_jilter_tar_location="$1"
    jilter_build_location="$2"
    jilter_build_name="$3"

    mkdir -p ${sandbox_jilter_tar_location}

    if [ ! -d ${jilter_build_location} ]; then
        echo -e "${RED} Jilter tar files are not present. Please follow instructions in the readme in the xgemail repo
        to build jilter ${NC}"
        exit 1
    else
        pushd "${jilter_build_location}"
        jilter_tar_file_string=$(ls *.tar)
        jilter_tar_files=(${jilter_tar_file_string})

        if [ ! ${#jilter_tar_files[@]} -eq 1 ] ; then
            echo -e "${RED} 0 or more than 1 tar files were found. There should be only tar file in the distribution folder ${NC}"
            echo -e "${RED} Follow instructions in the xgemail repo to build jilter ${NC}"
            popd > /dev/null
            clean_up_files
            exit 1
        else
            newfile_location=${sandbox_jilter_tar_location}${jilter_build_name}
            echo "Copying tar files to .xgemail_sandbox folder to ready it for deployment"
            rsync -a --progress "${jilter_tar_files[0]}" "${newfile_location}"

            if [ $? -eq 0 ]; then
                echo -e "${GREEN} Successfully copied jilter tar files to .xgemail_sandbox folder ${NC}"
                possible_clean_up_files+=${newfile_location}
            else
                echo -e "${RED} Failed to copy jilter tar files to .xgemail_sandbox folder ${NC}"
                popd > /dev/null
                clean_up_files
                exit 1
            fi
        fi
        popd > /dev/null
    fi
}

#TODO: remove or edit this after policy synchronization piece is done
# This creates place holder policy files
function build_policy_storage_for_jilter {
    policy_sandbox_location="${HOME}/.xgemail_sandbox/policy_storage/"
    mkdir -p ${policy_sandbox_location}

    global_config_folder="${policy_sandbox_location}config/outbound-relay-control/rate-limit/"
    mkdir -p ${global_config_folder}
    global_config_file="${global_config_folder}global.CONFIG"

    domains_config_folder="${policy_sandbox_location}config/outbound-relay-control/domains/"
    mkdir -p ${domains_config_folder}
    default_domain_config_file="${domains_config_folder}sophos.com.CONFIG"

    user_policy_folder="${policy_sandbox_location}config/outbound-relay-control/domains/sophos.com/"
    mkdir -p ${user_policy_folder}
    user_policy1_file="${user_policy_folder}b25l"
    user_policy2_file="${user_policy_folder}dGVzdGFkbWlu"

    #create empty policy files
    touch ${user_policy1_file}
    touch ${user_policy2_file}

    cat > ${global_config_file} << EOF
{"limit_by_domain":true,"limit_by_ip_address":false,"number_of_messages":2500,"duration":"PT300S"}
EOF

    cat > ${default_domain_config_file} << EOF
{"schema_version":20171026,"service_provider":"CUSTOM","addresses":["172.16.199.1"]}
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} Created default policy files for jilter ${NC}"
    else
        echo -e "${RED} Unable to create default policy files for jilter ${NC}"
        exit 1
    fi

}
: 'Checks if the required sasi images are present locally
'
function check_sasi {
    for image in "$@"; do
        docker inspect ${image} >/dev/null 2>&1
        if [ ! $? -eq 0 ]; then
            echo -e "${RED} ${image} cannot be found ${NC}"
            echo -e "${RED} For sasi-daemon, follow the instructions in the readme here
            https://git.cloud.sophos/projects/EMAIL/repos/sasi-docker/browse ${NC}"

            echo -e "${RED} For sasi-service, follow the instructions in the readme here
            https://git.cloud.sophos/projects/EMAIL/repos/sasi-service/browse ${NC}"

            exit 1
        else
            echo -e "${GREEN} Docker image ${image} confirmed to be present ${NC}"
        fi
    done
}

: 'Checks if the user can log into AWS ECR to download the necessary images
'
function check_login_to_aws {
    #Setup login to amazon ECR
    $(aws ecr get-login --no-include-email --region us-east-2) >/dev/null 2>&1

    if [ ! $? -eq 0 ]; then
        echo -e "${RED} Unable to log into AWS ECR. Check your AWS credentials configuration ${NC}"
        echo -e "${RED} Please take a look at the README.md file under ${XGEMAIL_HOME}xgemail-infrastructure/docker ${NC}"
        exit 1
    else
        echo -e "${GREEN} Successfully logged into AWS ECR ${NC}"
    fi

    #Pulling sasi images
    docker pull 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/sasi-service:latest
    docker pull 283871543274.dkr.ecr.us-east-2.amazonaws.com/xgemail/sasi-daemon:latest
}

function download_libspf_package {
    # Make sure user has updated permissions in /etc/sudoers file
    #Create packages directory
    sudo mkdir -p /opt/sophos/packages
    sudo chmod -R 777 /opt/sophos/packages

    #Download libspf package from S3 bucket
    aws --region us-east-1 s3 cp s3://cloud-sandbox-3rdparty/xgemail/libspf2-1.2.10-9.tar.gz /opt/sophos/packages

    if [ $? -eq 0 ]; then
      echo -e "${GREEN} Successfully downloaded libspf package from S3 ${NC}"
    else
      echo -e "${RED} libspf download was failed. Please check the permissions"
    fi
}

: 'Checks if the input docker instance is up.
'
function check_service_up {
    if [ $# -eq 0 ]; then
        echo -e "${RED} No service specified ${NC}"
        exit 1
    fi

    echo "Waiting for $1 to be fully up."
    count=0
    max_count=12 # Multiply this number by 5 for total wait time, in seconds.
    while [[ $count -le $max_count ]]; do
        startup_check="$(docker ps --filter=name=$1 --format {{.Status}} | grep -c Up)"
        if [[ $startup_check -ne 1 ]]; then
            count=$((count+1))
            sleep 5
        else
            count=$((max_count+1))
        fi
    done

    if [[ $startup_check -ne 1 ]]; then
        echo -e "${RED} $1 did not start properly.  Please check the logs ${NC}"
        exit 1
    else
        echo "$1 is up!"
    fi
}

: 'Checks if the specified deployed war files are up and running in Tomcat
'
function check_tomcat_startup()
{
    service_url="$1"
    shift
    local minutes=20
    echo "Checking deployment of wars '$@' in background"
    # echo "You can check the deployment status visually at 'http://localhost:9898/manager' using
    # username: admin and pwd: Test1234"
    # echo "You can also follow the logs using 'docker logs -f mail-service'"
    sleep 30
    local now=$(date +%s)
    local deadline=$(($now + $minutes*60))
    local running_services=()
    while (($now < $deadline)); do
        startup_check=$(curl -u script:script -s -o /dev/null -m 5 -w "%{http_code}" http://${service_url}/manager/text/list)
        if [[ $startup_check -eq 200 ]]; then
            for service in "$@"; do
                if [[ " ${running_services[@]} " =~ " ${service} " ]]; then
                  continue
                fi
                service_running=$(curl -s -u script:script http://${service_url}/manager/text/list | grep ${service}-services | awk -F":" '{print $2}')

                if [[ "${service_running}" = "running" ]]; then
                    echo -e "Deployment of wars ${service} done!"
                    running_services+=(${service})
                fi
            done
            if [ ${#running_services[@]} -eq $# ]; then
                echo -e "${GREEN} All wars <$@> up ${NC}"
                return 0
            fi
        fi
        sleep 10
        now=$(date +%s)
    done
    echo -e "${RED} Wars in tomcat did not startup in ${minutes} minutes. They might need more time or there may be something wrong. Check the logs ${NC}"
    return 1
}


: ' This function concatenates the bootstrap properties in the appserver in nova with the addendum bootstrap
properties for email.
'
function create_mail_bootstrap()
{
    echo -e "${GREEN} Creating bootstrap.properties file from nova appserver bootstrap properties
    and email addendum bootstrap properties ${NC}"
    local addendum_file="${xgemail_infrastructure_location}/docker/sophos_cloud_tomcat/config/xgemail_addendum_bootstrap.properties"

    if [ ! -f "${nova_bootstrap_file}" ]; then
      echo -e "${RED} bootstrap file not found at ${nova_bootstrap_file}. Confirm to ensure file exists ${NC}"
      exit 1
    fi

    if [ ! -f "${addendum_file}" ]; then
      echo -e "${RED} addendum bootstrap file not found at ${addendum_file}. Confirm to ensure file exists ${NC}"
      exit 1
    fi

    if [ ! -f "${nova_bootstrap_file_original_copy}" ]; then
      echo -e "${RED} Original bootstrap file not found at ${nova_bootstrap_file_original_copy}. Run <./xgemail.sh initialize>  ${NC}"
      exit 1
    fi


    cat $nova_bootstrap_file_original_copy $addendum_file > $mail_bootstrap_file

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} Successfully concatenated and created bootstrap properties file ${mail_bootstrap_file} ${NC}"
    else
        echo -e "${RED} Failed to created bootstrap properties file ${mail_bootstrap_file} ${NC}"
        exit 1
    fi
}

: 'This function sets up all the necessary war files needed to support the ui in nova tomcat
'
function setup_ui {
    echo -e "${YELLOW} Setting up UI ${NC}"
    check_service_up "nova_hub_1"

    deploy_wars "nova_hub_1" $1 "api" "hub" "core"
    check_tomcat_startup ${nova_tomcat_url}  "api" "hub" "core"
    if [ $? -eq 0 ]; then
      echo -e "${GREEN} Setup for UI complete ${NC}"
    else
      echo -e "${RED} Failed to setup UI ${NC}"
    fi
}

: 'This function destroy all docker containers brought up; removes files that have to be removed on
clean up
'
function clean_up {
    echo -e "${YELLOW} CLEANING UP ${NC}"

    clean_up_files
    $(docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${inbound_compose} -f ${orchestrator_location}${outbound_compose} down)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} Successfully cleaned up ${NC}"
        exit 0
    else
        echo -e "${RED} Clean up was unsuccessful ${NC}"
        exit 1
     fi
}

: 'Restores nova files edited when initialization function is called
'
function clean_up_nova_initialization
{
    echo -e "${YELLOW} Cleaning up nova initialization ${NC}"

    if [ -f ${nova_bootstrap_file_original_copy} ]; then

        mv ${nova_bootstrap_file_original_copy} ${nova_bootstrap_file}

        if [ $? -eq 0 ]; then
            echo -e "${GREEN} Successfully restored ${nova_bootstrap_file} ${NC}"
        else
            echo -e "${RED} Clean up was unsuccessful. Unable to restore ${nova_bootstrap_file} ${NC}"
        fi
    fi

    if [ -f ${nova_docker_compose_original_copy} ]; then

        mv ${nova_docker_compose_original_copy} ${nova_docker_compose_single}

        if [ $? -eq 0 ]; then
            echo -e "${GREEN} Successfully restored ${nova_docker_compose_single} ${NC}"
        else
            echo -e "${RED} Clean up was unsuccessful. Unable to restore ${nova_docker_compose_single} ${NC}"
        fi
    fi
}

: 'Removes files that have to be deleted
'
function clean_up_files {
    if [ ${#possible_clean_up_files} -gt 0 ]; then
        echo -e "${YELLOW} Cleaning up files ${possible_clean_up_files[@]} ${NC}"
        for file in ${possible_clean_up_files}; do
            rm -f ${file}
            if [ $? -eq 0 ]; then
                echo "${file} removed"
            else
                echo -e "${RED} Unable to remove file ${file} ${NC}"
            fi
        done
    else
        echo -e "${YELLOW} No files to clean up ${NC}"
    fi
}

function override_files {
    if [ ! $# -eq 2 ]; then
        echo -e "${RED} This function needs two input arguments ${NC}"
        exit 1
    fi

    for file in "$@"; do
        if [ ! -f ${file} ]; then
            echo -e "${RED} ${file} could not be found. Ensure it exists at the right location ${NC}"
            exit 1
        fi
    done

    echo "Overwriting $1 with $2"
    cp $2 $1

    if [ $? -eq 0 ]; then
        echo "Successfully replaced $1 with $2"
    else
        echo -e "${RED} There was an error replacing $1 with $2 ${NC}"
        exit 1
    fi
}

: 'This is a wrapper function around some commonly used docker-compose commands
'
function docker_compose_command
{
    base_compose_full=${orchestrator_location}${base_compose}
    inbound_compose_full=${orchestrator_location}${inbound_compose}
    outbound_compose_full=${orchestrator_location}${outbound_compose}

    all_command="docker-compose -f ${base_compose_full} -f ${inbound_compose_full} -f ${outbound_compose_full}"
    case "$2" in
        inbound)
        docker-compose -f ${base_compose_full} -f ${inbound_compose_full} $1 $3
        ;;
        outbound)
        docker-compose -f ${base_compose_full} -f ${outbound_compose_full} $1 $3
        ;;
        all)
        ${all_command} $1 $3
        ;;
        *)
        ${all_command} $1 $3 $2
        ;;
    esac
}

function join {
    local IFS="$1";
    shift;
    echo "$*";
}

function check_nova_up {
  echo ""
  echo ""

  read -p "Have you started Nova? If not, press "n" to exit and start NOVA. If yes, press "y" to continue" -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 0
  fi
}

function usage {
    cat <<EOF
Xgemail Sandbox

Usage:
  ./xgemail.sh COMMAND OPTIONS

Commands                                                                            Required                                                        Optional
help         get usage info
initialize   setup steps before starting up nova
deploy       deploy, provision and start containers                                 inbound | outbound | all                                           ui
hot_deploy   hot deploy artifacts(NOTE: artifacts have to be built first)           mail | mail-inbound | mailoutbound
                                                                                    jilter-inbound | jilter-outbound | jilter-mf-inbound | jilter-mf-outbound
                                                                                    postfix-is | postfix-cd | postfix-cs | postfix-id |
                                                                                    ui_wars

status       List status of created containers
up           create and start containers without any provisioning                   <service_name> | inbound | outbound | all                          [-d]
start        start stopped containers                                               <service_name> | inbound | outbound | all                          [-d]
stop         stop started containers                                                <service_name> | inbound | outbound | all                          [-d]
restart      restart started containers                                             <service_name> | inbound | outbound | all                          [-d]
create       create services without starting them                                  <service_name> | inbound | outbound | all                          [-d]
kill         kill containers                                                        <service_name> | inbound | outbound | all                          [-d]
             unlike stop, kill destroys the containers
             container has to be recreated in order to be started
rm           remove stopped containers                                              <service_name> | inbound | outbound | all                          [-d]
pause        pause services                                                         <service_name> | inbound | outbound | all                          [-d]
unpause      unpause services                                                       <service_name> | inbound | outbound | all                          [-d]
build        build or rebuild services                                              <service_name> | inbound | outbound | all                          [-d]

destroy      clean up and bring down all containers
             This does not remove images


Optional
-d          start in background
EOF
}

case "$1" in
    deploy)
        case "$2" in
            inbound)
                deploy_inbound
                ;;
            outbound)
                deploy_outbound
                ;;
            mfinbound)
                deploy_inbound
                ;;
            mfoutbound)
                deploy_outbound
                ;;
            all)
                deploy_all
                ;;
            *)
                echo "Usage: $0 <inbound | outbound | all>"
                ;;
       esac
       case "$3" in
         ui)
           setup_ui "false"
           ;;
       esac
       ;;
    hot_deploy)
        case "$2" in
            mail)
              deploy_wars "mail-service" "true" "mail"
              check_tomcat_startup ${email_tomcat_url} "mail"
              ;;

             malware-service)
              docker-compose -f ${orchestrator_location}${inbound_compose} restart malware-service
              ;;

            mail-inbound)
              deploy_wars "mail-service" "true" "mailinbound"
              check_tomcat_startup ${email_tomcat_url} "mailinbound"
              docker-compose -f ${orchestrator_location}${inbound_compose} restart mail-inbound
              ;;

            mailoutbound)
              deploy_wars "mail-service" "true" "mailoutbound"
              check_tomcat_startup ${email_tomcat_url} "mailoutbound"
              ;;

            ui_wars)
              setup_ui "true"
              ;;
              
            jilter-inbound)
              docker-compose -f ${orchestrator_location}${inbound_compose} restart jilter-inbound
              deploy_jilter inbound
              ;;
            jilter-outbound)
              docker-compose -f ${orchestrator_location}${outbound_compose} restart jilter-outbound
              deploy_jilter outbound
              ;;
            jilter-mf-inbound)
              docker-compose -f ${orchestrator_location}${inbound_compose} restart jilter-mf-inbound
              deploy_jilter mfinbound
              ;;
            jilter-mf-outbound)
              docker-compose -f ${orchestrator_location}${outbound_compose} restart jilter-mf-outbound
              deploy_jilter mfoutbound
              ;;
            postfix-is)
              provision_postfix postfix-is
              ;;
            postfix-cd)
              provision_postfix postfix-cd
              ;;
            postfix-cs)
              provision_postfix postfix-cs
              ;;
            postfix-id)
              provision_postfix postfix-id
              ;;
            *)
              echo "Usage: $0 <mail | mail-inbound | mailoutbound | ui_wars | jilter-inbound | jilter-outbound | jilter-mf-inbound | jilter-mf-outbound | postfix-is | postfix-cd | postfix-cs | postfix-id>"
              ;;
        esac
        ;;
    initialize)
        initialize
        ;;
    start)
        docker_compose_command $1 $2
        ;;
    stop)
        docker_compose_command $1 $2
        ;;
    restart)
        docker_compose_command $1 $2
        ;;
    create)
        docker_compose_command $1 $2
        ;;
    kill)
        docker_compose_command $1 $2
        ;;
    build)
        docker_compose_command $1 $2
        ;;
    rm)
        docker_compose_command $1 $2
        ;;
    pause)
        docker_compose_command $1 $2
        ;;
    unpause)
        docker_compose_command $1 $2
        ;;
    up)
        docker_compose_command $1 $2 $3
        ;;
    status)
        docker_compose_command ps all
        ;;
    help)
        usage
        ;;
    destroy)
        clean_up_nova_initialization
        clean_up
        ;;
    *)
        usage
        ;;
esac
