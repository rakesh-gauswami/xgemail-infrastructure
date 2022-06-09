variable "bulk_sender_automation_schedule" {
  type        = string
  description = "The schedule expression for bulk sender automation event rule"
  default     = "cron(0 * * * ? *)"
}

variable "bulk_sender_automation_schedule_enabled" {
  type        = bool
  description = "Enable or disable the bulk sender automation schedule"
  default     = true
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
