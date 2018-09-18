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

# Start the containers manually. this will start localstack and all containers configure in docker-compose.yml file
docker-compose up -d

# check if containers are running
docker-compose ps

# kill localstack-xgemail if started and call docker-compose up -d
# once localstack-xgemail is up, populate s3, sqs, sns
./do-it.sh

# some useful aws commands

# list s3 buckets
aws --endpoint-url=http://localhost:4572 s3 ls s3://

# copy file to a bucket: eg copy test.data file to xgemail-policy bucket
aws --endpoint-url=http://localhost:4572 s3 cp test.data s3://xgemail-policy/

# delete a file from a bucket, eg test.data
aws --endpoint-url=http://localhost:4572 s3 rm s3://xgemail-policy/test.data

# send message to an SQS queue, eg Xgemail_Delay
aws --endpoint-url=http://localhost:4576 sqs send-message --queue-url http://localhost:4576/queue/Xgemail_Delay --message-body 'Test Message!!'

# receive a message from a queue, eg Xgemail_Delay
aws --endpoint-url=http://localhost:4576 sqs receive-message --queue-url http://localhost:4576/queue/Xgemail_Delay

# delete a message from a queue, eg Xgemail_Delay, receipt-handle is from receive-message
aws --endpoint-url=http://localhost:4576 sqs delete-message --queue-url http://localhost:4576/queue/Xgemail_Delay --receipt-handle '86817749-528f-4a21-b578-bd51ff2a3cf2#e0b1cf55-9532-4812-ae27-069b53d035e3'

# create a SNS topic, eg test-topic
aws --endpoint-url=http://localhost:4575 sns create-topic --name test-topic --region us-east-1

# list topics
aws --endpoint-url=http://localhost:4575 sns list-topics --region us-east-1

# list subscriptions
aws --endpoint-url=http://localhost:4575 list-subscriptions

# subscribe to a topic
aws --endpoint-url=http://localhost:4575 sns subscribe --topic-arn arn:aws:sns:us-east-1:123456789012:test-topic --protocol email --notification-endpoint myemail@fake.com --region us-east-1

# publish a message to the topic
aws --endpoint-url=http://localhost:4575 sns publish --topic-arn arn:aws:sns:us-east-1:123456789012:test-topic --message 'Test Message!!' --region us-east-1

