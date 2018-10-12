#!/bin/bash

XGEMAIL_HOME_DIR=${XGEMAIL_HOME}
xgemail_infrastructure_location="${XGEMAIL_HOME_DIR}xgemail-infrastructure/"
orchestrator_location="${xgemail_infrastructure_location}orchestrator/"
tomcat_wars=()
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color


function deploy_inbound {
    echo -e "${GREEN} user selected inbound ${NC}"
    echo -e "${GREEN} Services needed for inbound mail-flow will be started ${NC}"
    echo ""
    tomcat_wars=("mail" "mailinbound")
    postfix_services=("postfix-is" "postfix-cd")

    create_mail_bootstrap

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} Bootstrap properties creation completed successfully ${NC}"
    else
        echo "${RED} creating mail bootstrap properties failed ${NC}"
        exit 1
    fi

    deploy_mail

    docker-compose -f ${orchestrator_location}docker-compose-base.yml -f ${orchestrator_location}docker-compose-inbound.yml up -d

    provision_localstack

    provision_postfix
}

function deploy_outbound {
    echo -e "${GREEN} user selected outbound ${NC}"
    echo -e "${GREEN} Services needed for outbound mail-flow will be started ${NC}"
    echo ""
    tomcat_wars=("mail" "mailoutbound")

    create_mail_bootstrap

    deploy_mail

    docker-compose -f ${orchestrator_location}docker-compose-base.yml -f ${orchestrator_location}docker-compose-outbound.yml up -d
}

function provision_postfix {
    for service in "${postfix_services[@]}"; do
        echo -e "${GREEN} provisioning ${service} started ${NC}"
        docker exec ${service} /opt/run.sh
        echo -e "${GREEN} provisioning ${service} successfully completed ${NC}"
    done
}

function provision_localstack {
    echo -e "${GREEN} provisioning localstack started ${NC}"
    bash ${orchestrator_location}do_it.sh
    echo -e "${GREEN} provisioning localstack successfully completed ${NC}"
}

: 'This function retrieves the necessary war files specified in the services variable for the users
current local sophos cloud branch.
It then copies into a folder with a standard name to enable mounting into a docker
container.
'
function deploy_mail {
    echo -e "${GREEN} Starting to deploy ${tomcat_wars[@]} ${NC}"
    pushd ${HOME}/g/cloud/sophos-cloud >/dev/null 2>&1
    raw_branch=$(git rev-parse --abbrev-ref HEAD)
    branch=$(echo $raw_branch | tr / _ | tr - _)

    services_count=${#tomcat_wars[@]}
    services_found=()
    warfiles_found=()
    for war in "${tomcat_wars[@]}"; do
        local spath="./${war}-services/build/libs/${war}-services-${branch}-LOCAL.war"
        if [ -e "$spath" ]; then
            warfiles_found+=("$spath")
            services_found+=("$war")
        fi
    done

    war_count=${#warfiles_found[@]}
    if [[ $war_count -ne $services_count ]]; then
        echo "found services: [${services_found[@]}] , expected: [${tomcat_wars[@]}]"
        echo "All war files were not available in the current branch"
        echo "Please ensure all war files are available"
        comma_seperated_services=$(join , ${tomcat_wars[@]})
        echo "Run './gradlew {"$comma_seperated_services"}-services:assemble' in the sophos cloud repo"
        exit 1
    else
        echo "War files have been indexed"
    fi

    war_file_location="${HOME}/.xgemail_sandbox/wars"

    echo ${war_file_location}
    mkdir -p ${war_file_location}

    if [ $? -eq 0 ]; then
        echo "cool"
    fi


    echo "Copying WAR files to ${war_file_location} for deployment"
    newfiles=""
    mkdir -p ${war_file_location}
    for file in "${warfiles_found[@]}" ; do
        filename=$(echo "$file" | xargs -n 1 basename)
        prefix=$(echo "$filename" | awk -F"-" '{print $1}')
        newfile=$(echo "$prefix"-services-NOVA-LOCAL.war)
        rsync -a --progress "$file" "${war_file_location}/$newfile"
        newfiles+="|$newfile|"
    done
    popd >/dev/null

    echo -e "${GREEN} successfully deployed ${warfiles_found[@]} ${NC}"

#    echo "Clearing out previously deployed WAR files"
#    for file in ${war_file_location}; do
#        if [[ $(echo "$newfiles" | grep -o "|$(basename $file)|" | wc -w) -eq 0 ]]; then
#            rm -rf "$file"
#        fi
#    done

    tomcat_wars=()
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

    echo "successfully concatenated and created bootstrap properties file $file"
}



function join {
    local IFS="$1";
    shift;
    echo "$*";
}


: ' This function takes the XGEMAIL_HOME env variable and adds a forward slash if it is missing one
 '
function provision_home_directory_path {
    if [[ ! ${XGEMAIL_HOME_DIR} == */ ]]; then
        XGEMAIL_HOME_DIR="${XGEMAIL_HOME_DIR}/"
    fi
    echo ${XGEMAIL_HOME_DIR}
}

provision_home_directory_path

case "$1" in
    deploy)
        case "$2" in
            inbound)
                deploy_inbound
                ;;
            outbound)
                deploy_outbound
                ;;

            both)
                ;;
            *)
                echo "unknown option"
                ;;
       esac
    ;;
    *)
        echo "unknown option"
    ;;
esac