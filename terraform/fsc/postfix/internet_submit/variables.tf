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

variable "internet_submit_bucket" {
  type        = string
  description = "internet_submit_bucket"
}

variable "internet_submit_sqs_queue" {
  type        = string
  description = "internet_submit_sqs_queue name"
}

variable "scan_events_sns_topic" {
  type        = string
  description = "scan_events_sns_topic name"
}

variable "firehose_jilter_helo_telemetry_stream_name" {
  type        = string
  description = "firehose_jilter_helo_telemetry_stream_name"
}

variable "firehose_msg_history_v2_stream_name" {
  type        = string
  description = "firehose_msg_history_v2_stream_name"
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

variable "message_history_events_sns_topic" {
  type        = string
  description = "message_history_events_sns_topic name"
}

variable "message_history_status_sns_topic" {
  type        = string
  description = "msg_history_status_sns_topic"
}

variable "policy_bucket" {
  type        = string
  description = "policy_bucket"
}

variable "relay_control_sns_topic" {
  type        = string
  description = "relay_control_sns_topic"
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
