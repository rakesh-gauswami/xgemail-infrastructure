#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'

base_compose="docker-compose-base.yml"
inbound_compose="docker-compose-inbound.yml"
outbound_compose="docker-compose-outbound.yml"

possible_clean_up_files=()

function deploy_inbound {
    check_login_to_aws
    set_home
    
    echo -e "${YELLOW} user selected inbound ${NC}"
    echo -e "${YELLOW} Services needed for inbound mail-flow will be started ${NC}"
    echo ""

    deploy_jilter inbound

    create_mail_bootstrap

    docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${inbound_compose} up -d

    check_mail_service_up

    deploy_mail "mail" "mailinbound"

    provision_localstack
 
    provision_postfix "postfix-is" "postfix-cd"

    check_tomcat_startup "mail" "mailinbound"
}

function deploy_outbound {
    check_login_to_aws
    set_home

    echo -e "${YELLOW} user selected outbound ${NC}"
    echo -e "${YELLOW} Services needed for outbound mail-flow will be started ${NC}"
    echo ""

    deploy_jilter outbound

    create_mail_bootstrap

    docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${outbound_compose} up -d

    check_mail_service_up

    deploy_mail "mail" "mailoutbound"

    provision_localstack
 
    provision_postfix "postfix-cs" "postfix-id"

    check_tomcat_startup "mail" "mailoutbound"
}

function deploy_all {
    check_login_to_aws
    set_home

    echo -e "${YELLOW} user selected all ${NC}"
    echo -e "${YELLOW} Services needed for both inbound and outbound mail-flow will be started ${NC}"
    echo ""

    deploy_jilter all

    create_mail_bootstrap

    docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${inbound_compose} -f ${orchestrator_location}${outbound_compose} up -d

    check_mail_service_up

    deploy_mail "mail" "mailinbound" "mailoutbound"

    provision_localstack
 
    provision_postfix "postfix-cs" "postfix-id" "postfix-is" "postfix-cd"

    check_tomcat_startup "mail" "mailoutbound" "mailinbound"
}

function provision_postfix {
    if [ "$#" -eq 0 ]; then
        echo -e "${RED} No postfix instances specified for provisioning ${NC}"
        clean_up
        exit 1
    fi
    for service in "$@"; do
        echo -e "${GREEN} provisioning ${service} started ${NC}"
        docker exec ${service} /opt/run.sh
        if [ $? -eq 0 ]; then
            echo -e "${GREEN} provisioning ${service} successfully completed ${NC}"
        else
            echo -e "${RED} provisioning ${service} failed ${NC}"
            clean_up
            exit 1
        fi
    done
}

function provision_localstack {
    echo -e "${GREEN} provisioning localstack started ${NC}"
    bash ${orchestrator_location}do_it.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN} provisioning localstack successfully completed ${NC}"
    else
        echo -e "${RED} provisioning localstack failed ${NC}"
        clean_up
        exit 1
    fi
}

: 'This function retrieves the necessary war files specified in the services variable for the users
current local sophos cloud branch.
It then copies into a folder with a standard name to enable mounting into a docker
container.
'
function deploy_mail {
    if [ "$#" -eq 0 ]; then
        echo -e "${RED} No wars specified for deployment ${NC}"
        clean_up
        exit 1
    fi

    echo -e "${GREEN} Starting to deploy '$@' ${NC}"
    pushd ${HOME}/g/cloud/sophos-cloud >/dev/null 2>&1
    raw_branch=$(git rev-parse --abbrev-ref HEAD)
    branch=$(echo $raw_branch | tr / _ | tr - _)

    services_count="$#"
    services_found=()
    warfiles_found=()
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
        echo "All war files were not available in the current branch"
        echo "You may not have assembled the necessary wars. Please ensure all war files are available"
        comma_seperated_services=$(join , "$@")
        echo "Run './gradlew {"$comma_seperated_services"}-services:assemble' in the sophos cloud repo"
        clean_up
        exit 1
    else
        echo "War files have been indexed"
    fi

    war_file_location="${HOME}/.xgemail_sandbox/wars"

    mkdir -p ${war_file_location}

    if [ ! $? -eq 0 ]; then
        echo -e "${RED} Failed to create ${war_file_location} ${NC}"
        clean_up
        exit 1
    fi
    tomcat_webapps_loc="mail-service:/usr/local/tomcat/webapps/"

    for file in "${warfiles_found[@]}" ; do
        filename=$(echo "$file" | xargs -n 1 basename)
        prefix=$(echo "$filename" | awk -F"-" '{print $1}')
        newfile=$(echo "$prefix"-services.war)
        newfile_location="${war_file_location}/$newfile"
        rsync -a --progress "${file}" "${newfile_location}"
        if [ ! $? -eq 0 ]; then
            echo -e "${RED} Failed to copy over ${file} to ${newfile_location} ${NC}"
            continue
        fi
        echo "Copying WAR file ${newfile_location} into Tomcat for deployment"
        docker cp "${newfile_location}" "${tomcat_webapps_loc}"
        if [ ! $? -eq 0 ]; then
            echo -e "${RED} Failed to copy ${newfile_location} into Tomcat containers ${NC}"
            echo "try recopying the war files into the tomcat container using 'docker cp <source> container_name:<destination>'"
            continue
        fi
        newfiles+="|$newfile|"
    done

    popd >/dev/null

    echo -e "${GREEN} successfully copied ${newfiles} into Tomcat ${NC}"
}

function deploy_jilter()
{
    jilter_location="${XGEMAIL_HOME}xgemail/"
    
    sandbox_inbound_jilter_tar_location="${HOME}/.xgemail_sandbox/jilter/inbound/"
    sandbox_outbound_jilter_tar_location="${HOME}/.xgemail_sandbox/jilter/outbound/"
    
    jilter_inbound_build_location="${jilter_location}xgemail-jilter-inbound/build/distributions/"
    jilter_inbound_build_name="jilter_inbound.tar"

    jilter_outbound_build_location="${jilter_location}xgemail-jilter-outbound/build/distributions/"
    jilter_outbound_build_name="jilter_outbound.tar"

    case $1 in 
        inbound)
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_inbound_build_location} ${jilter_inbound_build_name}
        ;;
        outbound)
            deploy_jilter_helper ${sandbox_outbound_jilter_tar_location} ${jilter_outbound_build_location} ${jilter_outbound_build_name}
        ;;
        all)
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_inbound_build_location} ${jilter_inbound_build_name}
            deploy_jilter_helper ${sandbox_outbound_jilter_tar_location} ${jilter_outbound_build_location} ${jilter_outbound_build_name}
        ;;
        *)
        clean_up_files
        exit 1
        ;;
    esac
}

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

        echo ${jilter_tar_files[0]}
    

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
            echo ${newfile_location}
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

function check_login_to_aws {
    #Setup login to amazon ECR
    aws ecr get-login --no-include-email --region us-east-2 --profile docker-amzn >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        echo -e "${RED} Unable to log into AWS ECR. Check your AWS credentials configuration ${NC}"
        exit 1
    else
        echo -e "${GREEN} Successfully logged into AWS ECR ${NC}"
    fi
}

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

    xgemail_infrastructure_location="${XGEMAIL_HOME}xgemail-infrastructure/"
    orchestrator_location="${xgemail_infrastructure_location}orchestrator/"
}

function check_mail_service_up {
    echo "Waiting for mail-service to be fully up."
    count=0
    max_count=12 # Multiply this number by 5 for total wait time, in seconds.
    while [[ $count -le $max_count ]]; do
        startup_check=$(docker ps --filter='name=mail-service' --format {{.Status}} | grep -c "Up")
        if [[ $startup_check -ne 1 ]]; then
            count=$((count+1))
            sleep 5
        else
            count=$((max_count+1))
        fi
    done

    if [[ $startup_check -ne 1 ]]; then
        echo -e "${RED}Mail-service tomcat did not start properly.  Please check the logs ${NC}"
        clean_up 
        exit 1
    else
        echo "Mail-service is up!"
    fi
}

function check_tomcat_startup()
{
    local minutes=20
    echo "Checking deployment of wars '$@' in background"
    sleep 30
    local now=$(date +%s)
    local deadline=$(($now + $minutes*60))
    while (($now < $deadline)); do
        startup_check=$(curl -u script:script -s -o /dev/null -m 5 -w "%{http_code}" http://localhost:9898/manager/text/list)
        if [[ $startup_check -eq 200 ]]; then
            service_count=$(curl -s -u script:script http://localhost:9898/manager/text/list | grep services | awk -F":" '{print $1," ",$2}' | column -t | grep -c -v running)
            if [[ $service_count -eq 0 ]]; then
                echo -e "${GREEN} Deployment of wars '$@' done! ${NC}"
                exit 0
            fi
        fi
        sleep 10
        now=$(date +%s)
    done
    echo "${RED} Wars in tomcat did not startup in ${minutes} minutes. They might need more time or there may be something wrong. Check the logs ${NC}"
}


: ' This function concatenates the bootstrap properties in the appserver in nova with the addendum bootstrap
properties for email. The newly created bootstrap properties file can then be used to
'
function create_mail_bootstrap()
{
    echo -e "${GREEN} Creating bootstrap.properties file from nova appserver bootstrap properties
    and email addendum bootstrap properties ${NC}"
    local nova_bootstrap_file="${HOME}/g/nova/appserver/config/bootstrap.properties"
    local addendum_file="${xgemail_infrastructure_location}/docker/sophos_cloud_tomcat/config/xgemail_addendum_bootstrap.properties"

    if [ ! -f "${nova_bootstrap_file}" ]; then
      echo -e "${RED} bootstrap file not found at ${nova_bootstrap_file}. Confirm to ensure file exists ${NC}"
      exit 1
    fi

    if [ ! -f "${addendum_file}" ]; then
      echo -e "${RED} addendum bootstrap file not found at ${addendum_file}. Confirm to ensure file exists ${NC}"
      exit 1
    fi

    local file="${orchestrator_location}sophos_cloud_tomcat_bootstrap.properties"

    cat $nova_bootstrap_file $addendum_file > $file

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} Successfully concatenated and created bootstrap properties file ${file} ${NC}"
    else
        echo -e "${RED} Failed to created bootstrap properties file ${file} ${NC}"
        exit 1
    fi
}

function clean_up {
    echo -e "${YELLOW} CLEANING UP ${NC}"

    clean_up_files
    #TODO: break up line
    $(docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${inbound_compose} -f ${orchestrator_location}${outbound_compose} down)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} Successfully cleaned up ${NC}"
        exit 1
    else
        echo -e "${RED} Clean up was unsuccessful ${NC}"
        exit 1
     fi   
}

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

function join {
    local IFS="$1";
    shift;
    echo "$*";
}

# When the user hits ctrl-c to interrupt the process, clean up
trap clean_up INT


function usage {
    cat <<EOF
Xgemail Sandbox

Usage:
  ./xgemail.sh COMMAND OPTIONS

Commands                                                                            Options
help         get usage info                                                                                                       
deploy       deploy and start containers                                            inbound, outbound, all
hot_deploy   hot deploy artifacts(NOTE: artifacts have to be built first)           mail, mailinbound, mailoutbound
                                                                                    jilter-inbound, jilter-outbound
                                                                                    postfix-is, postfix-cd, postfix-cs, postfix-id
destroy      clean up and bring down all containers    
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

            all)
                deploy_all
                ;;
            *)
                echo "Usage: $0 <inbound | outbound>"
                ;;
       esac
        ;;
    hot_deploy)
        set_home
        case "$2" in
            mail)
            deploy_mail "mail"
            check_tomcat_startup "mail"
            ;;

            mailinbound)
            deploy_mail "mailinbound"
            check_tomcat_startup "mailinbound"
            ;;

            mailoutbound)
            deploy_mail "mailoutbound"
            check_tomcat_startup "mailoutbound"
            ;;

            jilter-inbound)
                deploy_jilter inbound  
                docker-compose -f ${orchestrator_location}${inbound_compose} restart jilter-inbound
                ;;
            jilter-outbound)
                deploy_jilter outbound
                docker-compose -f ${orchestrator_location}${outbound_compose} restart jilter-outbound
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
            echo "Usage: $0 <mail | mailinbound | mailoutbound | jilter-inbound | jilter-outbound | postfix-is | postfix-cd | postfix-cs | postfix-id>"
            ;;
        esac
        ;;
    help)
        usage
        ;;
    destroy)
        clean_up
        ;;
    *)
        usage
        ;;
esac