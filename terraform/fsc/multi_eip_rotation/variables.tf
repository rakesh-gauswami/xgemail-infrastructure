variable "lifecycle_hook_names" {
  description = "The AutoScaling Group LifecycleHook Names"
  type        = list(string)
}

variable "multi_eip_rotation_schedule" {
  description = "The schedule expression for multi eip rotation event rule"
  default     = "rate(45 minutes)"
}

variable "multi_eip_rotation_schedule_enabled" {
  description = "Enable or disable the multi eip rotation schedule"
  default     = "DISABLED"
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}