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

variable "message_history_v2_stream_name" {
  type        = string
  description = "message_history_v2_stream_name"
}

variable "message_history_bucket" {
  type        = string
  description = "msg_history_bucket"
}

variable "message_history_ms_bucket" {
  type        = string
  description = "msg_history_ms_bucket"
}

variable "message_history_dynamodb_table_name" {
  type        = string
  description = "msg_history_dynamodb_table_name"
}

variable "message_history_status_sqs_queue" {
  type        = string
  description = "message_history_status_sqs_queue"
}

variable "message_history_status_sns_topic" {
  type        = string
  description = "message_history_status_sns_topic"
}

variable "notifier_request_sqs_queue" {
  type        = string
  description = "notifier_request_sqs_queue"
}

variable "policy_bucket" {
  type        = string
  description = "policy_bucket"
}

variable "station_account_role_arn" {
  type        = string
  description = "station_account_role_arn"
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
