variable "alias" {
  type        = string
  description = "Alias for kms key"
}

variable "description" {
  type        = string
  description = "Description of kms key"
}

variable "ssm_root_path" {
  type        = string
  description = "SSM path to output key parameters"
}
