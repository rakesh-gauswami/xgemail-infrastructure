# vim: autoindent expandtab shiftwidth=2 filetype=terraform

variable "lifecycle_hook_names" {
  description = "The AutoScaling Group LifecycleHook Names"
  type        = list(string)
}

variable "tag_origin" {
  type = string
  # No default, set by tf-fsc.sh
}