variable "eip_monitor_schedule" {
  description = "The schedule expression for eip monitor event rule"
  default     = "rate(60 minutes)"
}

variable "eip_monitor_schedule_enabled" {
  description = "Enable or disable the eip monitor schedule"
  default     = "DISABLED"
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
