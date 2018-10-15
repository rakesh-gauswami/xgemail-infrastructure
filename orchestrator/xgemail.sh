#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

echo -e "${GREEN} Setting environment variable <XGEMAIL_HOME> to <~/g/email/> ${NC}"
echo -e "${BLUE} NOTE: XGEMAIL_HOME points to the directory above which xgemail-infrastructure and xgemail repo live locally ${NC}"
export XGEMAIL_HOME="${HOME}/g/email/"

echo "Xgemail Home is ${XGEMAIL_HOME}"
xgemail_infrastructure_location="${XGEMAIL_HOME}xgemail-infrastructure/"
orchestrator_location="${xgemail_infrastructure_location}orchestrator/"
tomcat_wars=()

provision_home_directory_path

function deploy_inbound {
    echo -e "${GREEN} user selected inbound ${NC}"
    echo -e "${GREEN} Services needed for inbound mail-flow will be started ${NC}"
    echo ""
    tomcat_wars=("mail")
    postfix_services=("postfix-is" "postfix-cd")

    create_mail_bootstrap

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} Bootstrap properties creation completed successfully ${NC}"
    else
        echo "${RED} creating mail bootstrap properties failed ${NC}"
        exit 1
    fi

    docker-compose -f ${orchestrator_location}docker-compose-base.yml -f ${orchestrator_location}docker-compose-inbound.yml up -d

    check_mail_up

    if [ $? -eq 0 ]; then 
        echo "mail-service is up!"
        deploy_mail
    else
        echo "${RED} mail-service tomcat did not start. Unable to deploy ${tomcat_wars[@]} ${NC}"
        exit 1
    fi

    provision_localstack

    provision_postfix

    check_tomcat_startup
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
        echo "You may not have assembled the necessary wars. Please ensure all war files are available"
        comma_seperated_services=$(join , ${tomcat_wars[@]})
        echo "Run './gradlew {"$comma_seperated_services"}-services:assemble' in the sophos cloud repo"
        exit 1
    else
        echo "War files have been indexed"
    fi

    war_file_location="${HOME}/.xgemail_sandbox/wars"

    mkdir -p ${war_file_location}

    if [ $? -eq 0 ]; then
        echo "cool"
    fi

    tomcat_webapps_loc="mail-service:/usr/local/tomcat/webapps/"

    for file in "${warfiles_found[@]}" ; do
        filename=$(echo "$file" | xargs -n 1 basename)
        prefix=$(echo "$filename" | awk -F"-" '{print $1}')
        newfile=$(echo "$prefix"-services.war)
        newfile_location="${war_file_location}/$newfile"
        rsync -a --progress "${file}" "${newfile_location}"
        echo "Copying WAR file ${newfile_location} into tomcat for deployment"
        docker cp "${newfile_location}" "${tomcat_webapps_loc}"
       newfiles+="|$newfile|"
    done

    popd >/dev/null

    echo -e "${GREEN} successfully copied ${newfiles} into Tomcat ${NC}"
}

function check_mail_up()
{
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
        exit 1
    fi
}

function check_tomcat_startup()
{
    local minutes=20
    echo "Checking deployment of wars <${tomcat_wars[@]}> in background"
    sleep 20
    local now=$(date +%s)
    local deadline=$(($now + $minutes*60))
    while (($now < $deadline)); do
        startup_check=$(curl -u script:script -s -o /dev/null -m 5 -w "%{http_code}" http://localhost:9898/manager/text/list)
        if [[ $startup_check -eq 200 ]]; then
            service_count=$(curl -s -u script:script http://localhost:9898/manager/text/list | grep services | awk -F":" '{print $1," ",$2}' | column -t | grep -c -v running)
            if [[ $service_count -eq 0 ]]; then
                echo -e "${GREEN} Deployment of wars <${tomcat_wars[@]}> done! ${NC}"
                return 0
            fi
        fi
        sleep 10
        now=$(date +%s)
    done
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
    hot_deploy)
        case "$2" in
            mail)
            tomcat_wars=("mail")
            deploy_mail
            if [ $? -eq 0 ]; then 
                check_tomcat_startup
            fi
            ;;
            mailinbound)
            tomcat_wars=("mailinbound")
            deploy_mail
            if [ $? -eq 0 ]; then 
                check_tomcat_startup
            fi
            ;;
            mailoutbound)
            tomcat_wars=("mailoutbound")
            deploy_mail
            if [ $? -eq 0 ]; then 
                check_tomcat_startup
            fi
            ;;
            *)
            echo "usage"
            ;;
        esac
        ;;

    *)
        echo "usage"
    ;;
esac