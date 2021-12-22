variable "mf_elb_o365_ip_sync_schedule" {
  description = "The schedule expression for mf elb o365 ip sync event rule"
  default     = "cron(0 0 * * ? *)"
}

variable "mf_elb_o365_ip_sync_schedule_enabled" {
  type        = bool
  description = "Enable or disable the mf elb o365 ip sync schedule"
  default     = false
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
