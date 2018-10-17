#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'

base_compose="docker-compose-base.yml"
inbound_compose="docker-compose-inbound.yml"
outbound_compose="docker-compose-outbound.yml"

nova_bootstrap_file="${HOME}/g/nova/appserver/config/bootstrap.properties"
mail_bootstrap_file="${orchestrator_location}sophos_cloud_tomcat_bootstrap.properties"
nova_bootstrap_file_original_copy="${HOME}/g/nova/appserver/config/bootstrap_copy.properties"

nova_docker_compose_single="${HOME}/g/nova/docker-compose-single.yml"
xgemail_replacement_nova_compose="${orchestrator_location}docker-compose-nova-single.yml"
nova_docker_compose_original_copy="${HOME}/g/nova/docker-compose-single_copy.yml"

sasi_service_image="email/sasi-service"
sasi_docker_image="email/sasi-daemon"

possible_clean_up_files=()

function initialize {
    set_home
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

    echo -e "${GREEN} Initialization Completed Successfully ${NC}"
}


function deploy_inbound {
    initialize
    # check_login_to_aws
    set_home
    
    echo -e "${YELLOW} user selected inbound ${NC}"
    echo -e "${YELLOW} Services needed for inbound mail-flow will be started ${NC}"
    echo ""

    check_sasi ${sasi_service_image} ${sasi_docker_image}

    create_mail_bootstrap

    docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${inbound_compose} up -d

    deploy_jilter inbound

    deploy_mail "mail" "mailinbound"

    provision_localstack
 
    provision_postfix "postfix-is" "postfix-cd"

    check_tomcat_startup "mail" "mailinbound"
}

function deploy_outbound {
    initialize
    check_login_to_aws
    set_home
    
    check_sasi ${sasi_service_image} ${sasi_docker_image}

    echo -e "${YELLOW} user selected outbound ${NC}"
    echo -e "${YELLOW} Services needed for outbound mail-flow will be started ${NC}"
    echo ""

    deploy_jilter outbound

    create_mail_bootstrap

    docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${outbound_compose} up -d

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

    deploy_mail "mail" "mailinbound" "mailoutbound"

    provision_localstack
 
    provision_postfix "postfix-cs" "postfix-id" "postfix-is" "postfix-cd"

    check_tomcat_startup "mail" "mailoutbound" "mailinbound"
}

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

: 'This function retrieves the necessary war files specified in the services variable for the users
current local sophos cloud branch.
It then copies into a folder with a standard name to enable mounting into a docker
container.
'
function deploy_mail {
    if [ "$#" -eq 0 ]; then
        echo -e "${RED} No wars specified for deployment ${NC}"
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
    tomcat_webapps_loc="mail-service:/usr/local/tomcat/webapps/"

    check_service_up mail-service

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
    jilter_inbound_build_name="xgemail-jilter-inbound-current.tar"

    jilter_outbound_build_location="${jilter_location}xgemail-jilter-outbound/build/distributions/"
    jilter_outbound_build_name="xgemail-jilter-outbound-current.tar"

    case $1 in 
        inbound)
            check_service_up jilter-inbound
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_inbound_build_location} ${jilter_inbound_build_name}
        ;;
        outbound)
            check_service_up jilter-outbound
            deploy_jilter_helper ${sandbox_outbound_jilter_tar_location} ${jilter_outbound_build_location} ${jilter_outbound_build_name}
        ;;
        all)
            check_service_up jilter-inbound
            deploy_jilter_helper ${sandbox_inbound_jilter_tar_location} ${jilter_inbound_build_location} ${jilter_inbound_build_name}
            
            check_service_up jilter-outbound
            deploy_jilter_helper ${sandbox_outbound_jilter_tar_location} ${jilter_outbound_build_location} ${jilter_outbound_build_name}
        ;;
        *)
        clean_up_files
        exit 1
        ;;
    esac

    build_policy_storage_for_jilter

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

function check_login_to_aws {
    #Setup login to amazon ECR
    aws ecr get-login --no-include-email --region us-east-2 >/dev/null 2>&1

    if [ ! $? -eq 0 ]; then
        echo -e "${RED} Unable to log into AWS ECR. Check your AWS credentials configuration ${NC}"
        echo -e "${RED} Please take a look at the README.md file under ${XGEMAIL_HOME}xgemail-infrastructure/docker ${NC}"
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
    echo -e "${RED} Wars in tomcat did not startup in ${minutes} minutes. They might need more time or there may be something wrong. Check the logs ${NC}"
}


: ' This function concatenates the bootstrap properties in the appserver in nova with the addendum bootstrap
properties for email. The newly created bootstrap properties file can then be used to
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

function clean_up {
    echo -e "${YELLOW} CLEANING UP ${NC}"

    clean_up_files
    #TODO: break up line
    $(docker-compose -f ${orchestrator_location}${base_compose} -f ${orchestrator_location}${inbound_compose} -f ${orchestrator_location}${outbound_compose} down)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} Successfully cleaned up ${NC}"
        exit 0
    else
        echo -e "${RED} Clean up was unsuccessful ${NC}"
        exit 1
     fi   
}

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

function docker_compose_command
{
    case "$2" in 
        inbound)
        docker-compose -f ${base_compose} -f ${inbound_compose} $1
        ;;
        outbound)
        docker-compose -f ${base_compose} -f ${outbound_compose} $1
        ;;
        all)
        docker-compose -f ${base_compose} -f ${inbound_compose} -f ${outbound_compose} $1
        ;;
        *)
        echo "Usage: $0 $1 <inbound | outbound | all> "
        ;;
    esac    
}

function join {
    local IFS="$1";
    shift;
    echo "$*";
}

function usage {
    cat <<EOF
Xgemail Sandbox

Usage:
  ./xgemail.sh COMMAND OPTIONS

Commands                                                                            Options
help         get usage info 
initialize   setup steps before starting up nova                                                                                                     
deploy       deploy and start containers                                            inbound, outbound, all
hot_deploy   hot deploy artifacts(NOTE: artifacts have to be built first)           mail, mailinbound, mailoutbound
                                                                                    jilter-inbound, jilter-outbound
                                                                                    postfix-is, postfix-cd, postfix-cs, postfix-id
start        start stopped containers                                               inbound, outbound, all
stop         stop started containers                                                inbound, outbound, all
restart      restart started containers                                             inbound, outbound, all                                                                                    
destroy      clean up and bring down all containers 
             This does not remove images
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
                echo "Usage: $0 <inbound | outbound | all>"
                ;;
       esac
        ;;
    hot_deploy)
        case "$2" in
            mail)
            set_home
            deploy_mail "mail"
            check_tomcat_startup "mail"
            ;;

            mailinbound)
            set_home
            deploy_mail "mailinbound"
            check_tomcat_startup "mailinbound"
            ;;

            mailoutbound)
            set_home
            deploy_mail "mailoutbound"
            check_tomcat_startup "mailoutbound"
            ;;

            jilter-inbound)
                set_home
                deploy_jilter inbound  
                docker-compose -f ${orchestrator_location}${inbound_compose} restart jilter-inbound
                ;;
            jilter-outbound)
                set_home
                deploy_jilter outbound
                docker-compose -f ${orchestrator_location}${outbound_compose} restart jilter-outbound
                ;;
            postfix-is)
                set_home
                provision_postfix postfix-is
                ;;
            postfix-cd)
                set_home
                provision_postfix postfix-cd
                ;;
            postfix-cs)
                set_home
                provision_postfix postfix-cs
                ;;
            postfix-id)
                set_home
                provision_postfix postfix-id
                ;;
            *)
            echo "Usage: $0 <mail | mailinbound | mailoutbound | jilter-inbound | jilter-outbound | postfix-is | postfix-cd | postfix-cs | postfix-id>"
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