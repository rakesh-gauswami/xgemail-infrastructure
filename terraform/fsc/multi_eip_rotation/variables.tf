variable "multi_eip_rotation_schedule" {
  type        = string
  description = "The schedule expression for multi eip rotation event rule"
  default     = "rate(45 minutes)"
}

variable "multi_eip_rotation_schedule_enabled" {
  type        = bool
  description = "Enable or disable the multi eip rotation schedule"
  default     = false
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
