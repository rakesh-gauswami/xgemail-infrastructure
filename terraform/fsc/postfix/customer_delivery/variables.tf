variable "build_branch" {
  type        = string
  description = "Bitbucket Branch"
}

variable "build_number" {
  type        = string
  description = "Build Number"
}

variable "build_tag" {
  type        = string
  description = "Build Tag"
}

variable "build_url" {
  type        = string
  description = "Build URL"
}

variable "firehose_msg_history_v2_stream_name" {
  type        = string
  description = "firehose_msg_history_v2_stream_name"
}

variable "message_history_events_sns_topic" {
  type        = string
  description = "msg_history_events_sns_topic"
}

variable "customer_submit_bucket" {
  type        = string
  description = "customer_submit_bucket"
}

variable "message_history_bucket" {
  type        = string
  description = "msg_history_bucket"
}

variable "message_history_ms_bucket" {
  type        = string
  description = "msg_history_ms_bucket"
}

variable "message_history_sqs_queue" {
  type        = string
  description = "msg_history_sqs_queue"
}


variable "message_history_status_sqs_queue" {
  type        = string
  description = "msg_history_status_sqs_queue"
}

variable "message_history_status_sns_topic" {
  type        = string
  description = "msg_history_status_sns_topic"
}

variable "message_history_v2_dynamodb" {
  type        = string
  description = "msg_history_v2_dynamodb"
}

variable "message_history_v2_stream_name" {
  type        = string
  description = "msg_history_v2_stream_name"
}

variable "policy_bucket" {
  type        = string
  description = "policy_bucket"
}

variable "customer_submit_sqs_queue" {
  type        = string
  description = "customer_submit_sqs_queue"
}

variable "customer_delivery_sqs_queue_sns_listener" {
  type        = string
  description = "customer_delivery_sqs_queue_sns_listener"
}

variable "customer_delivery_sqs_queue_sns_listener_url" {
  type        = string
  description = "customer_delivery_sqs_queue_sns_listener_url"
}

variable "station_vpc_id" {
  type        = string
  description = "station_vpc_id"
}

variable "station_name" {
  type        = string
  description = "station_name"
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}