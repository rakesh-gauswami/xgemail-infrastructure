locals {
  input_param_account_id             = nonsensitive(data.aws_ssm_parameter.account_id.value)
  input_param_account_name           = nonsensitive(data.aws_ssm_parameter.account_name.value)
  input_param_deployment_environment = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region         = nonsensitive(data.aws_ssm_parameter.primary_region.value)
}

data "aws_ssm_parameter" "account_id" {
  name     = "/central/account/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "account_name" {
  name     = "/central/account/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "deployment_environment" {
  provider = aws.parameters

  name = "/central/account/deployment-environment"
}

data "aws_ssm_parameter" "primary_region" {
  provider = aws.parameters

  name = "/central/account/primary-region"
}
