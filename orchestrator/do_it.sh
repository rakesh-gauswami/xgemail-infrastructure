#!/bin/bash

# This script is meant to bring up the Xgemail sandbox up in stages.
# By bringing up localstack first, and checking for uptime,
# the proper AWS configurations and initialization of services
# can be applied before starting up other services

ES_HOST="localhost:9200"

GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

gprintf() {
	printf "${GREEN}$@${NC}\n"
}
#ACCOUNT ID
AWS_ACCOUNT_ID="000000000000"

#S3 buckets
CUSTOMER_SUBMIT_BUCKET="xgemail-cust-submit"
EMERGENCY_INBOX_BUCKET="xgemail-emgcy-inbox"
MSG_HISTORY_BUCKET="xgemail-msg-history"
MSG_HISTORY_MS_BUCKET="xgemail-msg-hist-ms"
MSG_STATS_BUCKET="xgemail-msg-stats"
QUARANTINE_BUCKET="xgemail-quarantine"
CONNECTIONS_BUCKET="cloud-sandbox-connections"
#special S3 buckets
LAMDA_BUCKET="lamda"


#SQS
CUSTOMER_DELIVERY_SQS_QUEUE="sandbox-Xgemail_Customer_Delivery"
CUSTOMER_SUBMIT_SQS_QUEUE="sandbox-Xgemail_Customer_Submit"
CUSTOMER_DELIVERY_SQS_QUEUE_SNS_LISTENER="sandbox-Xgemail_Customer_Delivery_SNS_Listener"
DQS_SQS_QUEUE="sandbox-Xgemail_DQS"
DELAY_SQS_QUEUE="sandbox-Xgemail_Delay"
EMERGENCY_INBOX_SQS_QUEUE="sandbox-Xgemail_Emergency_Inbox_Delivery"
EMERGENCY_INBOX_SQS_QUEUE_SNS_LISTENER="sandbox-Xgemail_Emergency_Inbox_Delivery_SNS_Listener"
INTERNET_DELIVERY_SQS_QUEUE="sandbox-Xgemail_Internet_Delivery"
INTERNET_DELIVERY_SQS_QUEUE_SNS_LISTENER="sandbox-Xgemail_Internet_Delivery_SNS_Listener"
INTERNET_SUBMIT_SERVICE_SQS_QUEUE="sandbox-Internet_Submit_Service_Queue"

#MSG Queues
MSG_HISTORY_SQS_QUEUE="sandbox-Xgemail_MessageHistoryEvent_Delivery"
MSG_HISTORY_SQS_QUEUE_SNS_LISTENER="sandbox-Xgemail_MessageHistoryEvent_Delivery_SNS_Listener"
MSG_HISTORY_STATUS_SQS_QUEUE="sandbox-Xgemail_MessageHistory_Delivery_Status"
MSG_HISTORY_STATUS_SQS_QUEUE_SNS_LISTENER="sandbox-Xgemail_MessageHistory_Delivery_Status_SNS_Listener"
POLICY_SQS_QUEUE="sandbox-xgemail-policy"
MULTI_POLICY_SQS_QUEUE="sandbox-Xgemail_multi_policy"
NOTIFIER_REQUEST_SQS_QUEUE="sandbox-Xgemail_Notifier_Request"
QUARANTINE_SQS_QUEUE="sandbox-Xgemail_Quarantine_Delivery"
QUARANTINE_SQS_QUEUE_SNS_LISTENER="sandbox-Xgemail_Quarantine_Delivery_SNS_Listener"
POLICYASSIGNMENT_SQS_QUEUE="sandbox-PolicyAssignment_Xgemail"

#SASI Queues
SASI_OUTBOUND_REQUEST_SQS_QUEUE="sandbox-SASI_Outbound_Request"
SASI_OUTBOUND_RESPONSE_SQS_QUEUE="sandbox-SASI_Outbound_Response"

#DLQ queues
SASI_OUTBOUND_REQUEST_SQS_QUEUE_DLQ="sandbox-SASI_Outbound_Request-DLQ"
SASI_OUTBOUND_RESPONSE_SQS_QUEUE_DLQ="sandbox-SASI_Outbound_Response-DLQ"
SASI_REQUEST_SQS_QUEUE_DLQ="sandbox-SASI_Request-DLQ"
SASI_RESPONSE_SQS_QUEUE_DLQ="sandbox-SASI_Response-DLQ"
CUSTOMER_DELIVERY_SQS_QUEUE_SNS_LISTENER_DLQ="sandbox-Xgemail_Customer_Delivery_SNS_Listener-DLQ"
CUSTOMER_SUBMIT_SQS_QUEUE_DLQ="sandbox-Xgemail_Customer_Submit-DLQ"
DQS_SQS_QUEUE_DLQ="sandbox-Xgemail_DQS-DLQ"
DELAY_SQS_QUEUE_DLQ="sandbox-Xgemail_Delay-DLQ"
EMERGENCY_INBOX_SQS_QUEUE_DLQ="sandbox-Xgemail_Emergency_Inbox_Delivery-DLQ"
EMERGENCY_INBOX_SQS_QUEUE_SNS_LISTENER_DLQ="sandbox-Xgemail_Emergency_Inbox_Delivery_SNS_Listener-DLQ"
INTERNET_DELIVERY_SQS_QUEUE_DLQ="sandbox-Xgemail_Internet_Delivery-DLQ"
INTERNET_DELIVERY_SQS_QUEUE_SNS_LISTENER_DLQ="sandbox-Xgemail_Internet_Delivery_SNS_Listener-DLQ"
INTERNET_SUBMIT_SERVICE_SQS_QUEUE_DLQ="sandbox-Xgemail_Internet_Submit_Service-DLQ"
MSG_HISTORY_SQS_QUEUE_DLQ="sandbox-Xgemail_MessageHistoryEvent_Delivery-DLQ"
MSG_HISTORY_SQS_QUEUE_SNS_LISTENER_DLQ="sandbox-Xgemail_MessageHistoryEvent_Delivery_SNS_Listener-DLQ"
MSG_HISTORY_STATUS_SQS_QUEUE_DLQ="sandbox-Xgemail_MessageHistory_Delivery_Status-DLQ"
MSG_HISTORY_STATUS_SQS_QUEUE_SNS_LISTENER_DLQ="sandbox-Xgemail_MessageHistory_Delivery_Status_SNS_Listener-DLQ"
MULTI_POLICY_SQS_QUEUE_DLQ="sandbox-Xgemail_multi_policy-DLQ"
NOTIFIER_REQUEST_SQS_QUEUE_DLQ="sandbox-Xgemail_Notifier_Request-DLQ"
QUARANTINE_SQS_QUEUE_DLQ="sandbox-Xgemail_Quarantine_Delivery-DLQ"
QUARANTINE_SQS_QUEUE_SNS_LISTENER_DLQ="sandbox-Xgemail_Quarantine_Delivery_SNS_Listener-DLQ"

#SNS
DELAY_SNS_TOPIC="xgemail-delay-SNS"
DELETED_EVENTS_SNS_TOPIC="xgemail-deleted-events-SNS"
INTERNET_DELIVERY_SNS_TOPIC="xgemail-internet-delivery-SNS"
MSG_HISTORY_STATUS_SNS_TOPIC="xgemail-msg-history-delivery-status-SNS"
MSG_HISTORY_EVENTS_SNS_TOPIC="xgemail-msg-history-events-SNS"
MSG_STATISTICS_REJECTION_SNS_TOPIC="xgemail-msg-statistics-rejection-SNS"
MULTI_POLICY_SNS_TOPIC="xgemail-multi-policy-SNS"
POLICY_SNS_TOPIC="xgemail-policy-SNS"
QUARANTINED_EVENTS_SNS_TOPIC="xgemail-quarantined-events-SNS"
RELAY_CONTROL_SNS_TOPIC="xgemail-relay-control-SNS"
SCAN_EVENTS_SNS_TOPIC="xgemail-scan-events-SNS"
SUCCESS_EVENTS_SNS_TOPIC="xgemail-success-events-SNS"

gprintf "Waiting for localstack to be fully up."
count=0
max_count=2 # Multiply this number by 5 for total wait time, in seconds.
while [[ $count -le $max_count ]]; do
    startup_check=$(docker ps --filter='ancestor=localstack' --format {{.Status}} | grep -c "Up")
    if [[ $startup_check -ne 0 ]]; then
        count=$((count+1))
        sleep 5
    else
        count=$((max_count+1))
    fi
done

if [[ $startup_check -ne 0 ]]; then
    printf "${RED}localstack did not start properly.  Please check the logs."
    exit 1
    else
      gprintf "localstack is up!  Creating buckets"

      gprintf "CREATING S3 BUCKET CUSTOMER_SUBMIT_BUCKET"
      awslocal s3 mb s3://${CUSTOMER_SUBMIT_BUCKET}

      gprintf "CREATING S3 BUCKET EMERGENCY_INBOX_BUCKET"
      awslocal s3 mb s3://${EMERGENCY_INBOX_BUCKET}

      gprintf "CREATING S3 BUCKET MSG_HISTORY_BUCKET"
      awslocal s3 mb s3://${MSG_HISTORY_BUCKET}

      gprintf "CREATING S3 BUCKET MSG_HISTORY_MS_BUCKET"
      awslocal s3 mb s3://${MSG_HISTORY_MS_BUCKET}

      gprintf "CREATING S3 BUCKET MSG_STATS_BUCKET"
      awslocal s3 mb s3://${MSG_STATS_BUCKET}

      gprintf "CREATING S3 BUCKET QUARANTINE_BUCKET"
      awslocal s3 mb s3://${QUARANTINE_BUCKET}

      gprintf "CREATING S3 BUCKET CONNECTIONS_BUCKET"
      awslocal s3 mb s3://${CONNECTIONS_BUCKET}

      gprintf "Creating SQS"
      gprintf "CREATING CUSTOMER_DELIVERY_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${CUSTOMER_DELIVERY_SQS_QUEUE} | jq .

      gprintf "CREATING CUSTOMER_SUBMIT_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${CUSTOMER_SUBMIT_SQS_QUEUE} | jq .

      gprintf "CREATING CUSTOMER_DELIVERY_SQS_QUEUE_SNS_LISTENER"
      awslocal sqs create-queue --queue-name ${CUSTOMER_DELIVERY_SQS_QUEUE_SNS_LISTENER} | jq .

      gprintf "CREATING DQS_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${DQS_SQS_QUEUE} | jq .

      gprintf "CREATING DELAY_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${DELAY_SQS_QUEUE} | jq .

      gprintf "CREATING EMERGENCY_INBOX_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${EMERGENCY_INBOX_SQS_QUEUE} | jq .

      gprintf "CREATING EMERGENCY_INBOX_SQS_QUEUE_SNS_LISTENER"
      awslocal sqs create-queue --queue-name ${EMERGENCY_INBOX_SQS_QUEUE_SNS_LISTENER} | jq .

      gprintf "CREATING INTERNET_DELIVERY_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${INTERNET_DELIVERY_SQS_QUEUE} | jq .

      gprintf "CREATING INTERNET_DELIVERY_SQS_QUEUE_SNS_LISTENER"
      awslocal sqs create-queue --queue-name ${INTERNET_DELIVERY_SQS_QUEUE_SNS_LISTENER} | jq .

      gprintf "CREATING MSG_HISTORY_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${MSG_HISTORY_SQS_QUEUE} | jq .

      gprintf "CREATING MSG_HISTORY_SQS_QUEUE_SNS_LISTENER"
      awslocal sqs create-queue --queue-name ${MSG_HISTORY_SQS_QUEUE_SNS_LISTENER} | jq .

      gprintf "CREATING MSG_HISTORY_STATUS_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${MSG_HISTORY_STATUS_SQS_QUEUE} | jq .

      gprintf "CREATING MSG_HISTORY_STATUS_SQS_QUEUE_SNS_LISTENER"
      awslocal sqs create-queue --queue-name ${MSG_HISTORY_STATUS_SQS_QUEUE_SNS_LISTENER} | jq .

      gprintf "CREATING MSG_STATISTICS_SQS_QUEUE_SNS_LISTENER"
      awslocal sqs create-queue --queue-name ${MSG_STATISTICS_SQS_QUEUE_SNS_LISTENER} | jq .

      gprintf "CREATING POLICY_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${POLICY_SQS_QUEUE} | jq .

      gprintf "CREATING MULTI_POLICY_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${MULTI_POLICY_SQS_QUEUE} | jq .

      gprintf "CREATING NOTIFIER_REQUEST_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${NOTIFIER_REQUEST_SQS_QUEUE} | jq .

      gprintf "CREATING QUARANTINE_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${QUARANTINE_SQS_QUEUE} | jq .

      gprintf "CREATING QUARANTINE_SQS_QUEUE_SNS_LISTENER"
      awslocal sqs create-queue --queue-name ${QUARANTINE_SQS_QUEUE_SNS_LISTENER} | jq .

      gprintf "CREATING SASI_OUTBOUND_REQUEST_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${SASI_OUTBOUND_REQUEST_SQS_QUEUE} | jq .

      gprintf "CREATING SASI_OUTBOUND_RESPONSE_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${SASI_OUTBOUND_RESPONSE_SQS_QUEUE} | jq .

      gprintf "CREATING POLICY_ASSIGNMENT_SQS_QUEUE"
      awslocal sqs create-queue --queue-name ${POLICYASSIGNMENT_SQS_QUEUE} | jq .

      gprintf "CREATING DLQ "
      awslocal sqs create-queue --queue-name ${SASI_OUTBOUND_REQUEST_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${SASI_OUTBOUND_RESPONSE_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${SASI_REQUEST_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${SASI_RESPONSE_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${CUSTOMER_DELIVERY_SQS_QUEUE_SNS_LISTENER_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${CUSTOMER_SUBMIT_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${DQS_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${DELAY_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${EMERGENCY_INBOX_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${EMERGENCY_INBOX_SQS_QUEUE_SNS_LISTENER_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${INTERNET_DELIVERY_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${INTERNET_DELIVERY_SQS_QUEUE_SNS_LISTENER_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${INTERNET_SUBMIT_SERVICE_SQS_QUEUE_DLQ} | jq

      awslocal sqs create-queue --queue-name ${MSG_HISTORY_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${MSG_HISTORY_SQS_QUEUE_SNS_LISTENER_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${MSG_HISTORY_STATUS_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${MSG_HISTORY_STATUS_SQS_QUEUE_SNS_LISTENER_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${MULTI_POLICY_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${NOTIFIER_REQUEST_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${QUARANTINE_SQS_QUEUE_DLQ} | jq .

      awslocal sqs create-queue --queue-name ${QUARANTINE_SQS_QUEUE_SNS_LISTENER_DLQ} | jq .

      #SNS Topics
      gprintf "Creating SNS Topics"

      gprintf "CREATING DELAY_SNS_TOPIC"
      awslocal sns create-topic --name ${DELAY_SNS_TOPIC} | jq .

      gprintf "CREATING DELETED_EVENTS_SNS_TOPIC"
      awslocal sns create-topic --name ${DELETED_EVENTS_SNS_TOPIC} | jq .

      gprintf "CREATING INTERNET_DELIVERY_SNS_TOPIC"
      awslocal sns create-topic --name ${INTERNET_DELIVERY_SNS_TOPIC} | jq .

      gprintf "CREATING MSG_HISTORY_STATUS_SNS_TOPIC"
      awslocal sns create-topic --name ${MSG_HISTORY_STATUS_SNS_TOPIC} | jq .

      gprintf "CREATING MSG_STATISTICS_REJECTION_SNS_TOPIC"
      awslocal sns create-topic --name ${MSG_STATISTICS_REJECTION_SNS_TOPIC} | jq .

      gprintf "CREATING MULTI_POLICY_SNS_TOPIC"
      awslocal sns create-topic --name ${MULTI_POLICY_SNS_TOPIC} | jq .

      gprintf "CREATING POLICY_SNS_TOPIC"
      awslocal sns create-topic --name ${POLICY_SNS_TOPIC} | jq .

      gprintf "CREATING QUARANTINED_EVENTS_SNS_TOPIC"
      awslocal sns create-topic --name ${QUARANTINED_EVENTS_SNS_TOPIC} | jq .

      gprintf "CREATING RELAY_CONTROL_SNS_TOPIC"
      awslocal sns create-topic --name ${RELAY_CONTROL_SNS_TOPIC} | jq .

      gprintf "CREATING MSG_HISTORY_EVENTS_SNS_TOPIC"
      awslocal sns create-topic --name ${MSG_HISTORY_EVENTS_SNS_TOPIC} | jq .

      gprintf "CREATING SUCCESS_EVENTS_SNS_TOPIC"
      awslocal sns create-topic --name ${SUCCESS_EVENTS_SNS_TOPIC} | jq .

      #Subscribing
      gprintf "Creating SNS Subscribers"

      gprintf "SUBSCRIBING policy SNS TOPIC"
      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${POLICY_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${POLICY_SQS_QUEUE} | jq .

      gprintf "SUBSCRIBING Multi-policy SNS TOPIC"
      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${MULTI_POLICY_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MULTI_POLICY_SQS_QUEUE} | jq .

      gprintf "SUBSCRIBING Multi-Delay SNS TOPIC"
      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${DELAY_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${DELAY_SQS_QUEUE} | jq .

      gprintf "SUBSCRIBING Deleted Event SNS TOPIC"
      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${DELETED_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${DELETED_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_STATISTICS_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${INTERNET_DELIVERY_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${INTERNET_DELIVERY_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${INTERNET_DELIVERY_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_STATISTICS_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${INTERNET_DELIVERY_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${INTERNET_DELIVERY_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_STATUS_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${QUARANTINED_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${QUARANTINED_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_STATISTICS_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${QUARANTINED_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${QUARANTINE_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_STATUS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_STATUS_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${SUCCESS_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_HISTORY_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${SUCCESS_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${MSG_STATISTICS_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${SUCCESS_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${EMERGENCY_INBOX_SQS_QUEUE_SNS_LISTENER} | jq .

      awslocal sns subscribe \
          --topic-arn arn:aws:sns:us-east-1:${AWS_ACCOUNT_ID}:${SUCCESS_EVENTS_SNS_TOPIC} \
          --protocol sqs \
          --notification-endpoint arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:${CUSTOMER_DELIVERY_SQS_QUEUE_SNS_LISTENER} | jq .

      gprintf "localstack environment is set!"

fi