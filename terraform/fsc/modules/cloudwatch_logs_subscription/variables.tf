
variable "function_name" {
  description = "Name of Lambda Function"
  type        = string
}

variable "cloudwatch_filter_pattern" {
  description = "The cloudwatch filter pattern"
  type        = string
  default     = ""
}
