# vim: autoindent expandtab shiftwidth=2 filetype=terraform

locals {

  common_tags = {
    Application  = "xgemail-infrastructure"
    BusinessUnit = "MSG"
    Origin       = var.tag_origin
    OwnerEmail   = "SophosMailOps@sophos.com"
    Project      = "xgemail-infrastructure"
  }
}

terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.64.2"
    }
  }
  required_version = "~> 1.0.0"
}

provider "aws" {
  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "parameters"
  region = "us-east-1"
  default_tags {
    tags = local.common_tags
  }
}
