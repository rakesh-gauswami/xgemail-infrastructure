variable "ami_branch" {
  type        = string
  description = "AMI Bitbucket branch"
}

variable "build_branch" {
  type        = string
  description = "Bitbucket Branch"
}

variable "build_number" {
  type        = string
  description = "Build Number"
}

variable "build_result_key" {
  type        = string
  description = "Build Result Key"
}

variable "ami_build" {
  type        = string
  description = "AMI build number"
}

variable "msg_history_v2_bucket_name" {
  type        = string
  description = "msg_history_v2_bucket_name"
}

variable "firehose_msg_history_v2_stream_name" {
  type        = string
  description = "firehose_msg_history_v2_stream_name"
}

variable "msg_history_events_sns_topic" {
  type        = string
  description = "msg_history_events_sns_topic"
}

variable "station_vpc_id" {
  type        = string
  description = "station_vpc_id"
}

variable "station_name" {
  type        = string
  description = "station_name"
}

variable "customer_submit_bucket" {
  type        = string
  description = "customer_submit_bucket"
}

variable "msg_history_bucket" {
  type        = string
  description = "msg_history_bucket"
}

variable "msg_history_ms_bucket" {
  type        = string
  description = "msg_history_ms_bucket"
}

variable "msg_history_sqs_queue" {
  type        = string
  description = "msg_history_sqs_queue"
}

variable "relay_control_sns_topic" {
  type        = string
  description = "relay_control_sns_topic"
}

variable "policy_bucket" {
  type        = string
  description = "policy_bucket"
}

variable "customer_submit_sqs_queue" {
  type        = string
  description = "customer_submit_sqs_queue"
}

variable "scan_events_sns_topic" {
  type        = string
  description = "scan_events_sns_topic"
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
