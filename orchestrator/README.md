# Requirements:
* awscli-local. Install via: `pip install awscli-local`
* Java 1.8

# Instructions on setting up orchestrator for use with all xgemail containers

* The orchestrator is part of the xgemail repo
* 

# For Integration Tests to work
1. Add to /etc/hosts
	127.0.0.1   localstack-xgemail
2. Be sure that nova deploy single is up


# If elasticsearch does not come up and there is and error in the logs about infra.pyc do
docker-compose stop && docker-compose rm -f &&  docker system prune

# Start the containers
docker-compose up -d

#check if containers are running
docker-compose ps

#populate s3, sqs, sns
./do-it.sh
