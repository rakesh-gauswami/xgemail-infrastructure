locals {
  input_param_deployment_environment = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region         = nonsensitive(data.aws_ssm_parameter.primary_region.value)
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}

