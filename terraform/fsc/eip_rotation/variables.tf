variable "eip_rotation_schedule" {
  type        = string
  description = "The schedule expression for eip rotation event rule"
  default     = "rate(10 minutes)"
}

variable "eip_rotation_schedule_enabled" {
  type        = bool
  description = "Enable or disable the eip rotation schedule"
  default     = false
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}
