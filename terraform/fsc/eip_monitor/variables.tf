variable "eip_monitor_schedule" {
  type        = string
  description = "The schedule expression for eip monitor event rule"
  default     = "rate(60 minutes)"
}

variable "eip_monitor_schedule_enabled" {
  type        = bool
  description = "Enable or disable the eip monitor schedule"
  default     = false
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
