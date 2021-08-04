##################################################################################
# Variables
##################################################################################
variable "region" {
  description = "The AWS region to create resources in."
}

variable "environment" {
  description = "Environment like inf, dev, qa, prod"
  default     = "dev"
}

variable "vpc_name" {
  description = "Base of vpc name. Used to construct identifiers for all resources"
  default     = "CloudStation"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.1.0.0/16"
}

variable "enable_dns_hostnames" {
  description = "should be true if you want to use private DNS within the VPC"
  default     = true
}

variable "enable_dns_support" {
  description = "should be true if you want to use private DNS within the VPC"
  default     = true
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  default     = "default"
}

variable "tags" {
  type = map(string)
  default = {
    Project       = "xgemail"
    Application   = "CloudEmail"
    BusinessUnit  = "MSG"
    OwnerEmail    = "SophosMailOps@sophos.com"
  }
}
