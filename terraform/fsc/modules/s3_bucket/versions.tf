terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 3.47.0"
      configuration_aliases = [aws.parameters]
    }
  }

  required_version = ">= 1.0.0"
}
