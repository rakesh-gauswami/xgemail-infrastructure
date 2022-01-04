locals {
  input_param_account_name           = data.aws_ssm_parameter.account_name.value
  input_param_account_type           = data.aws_ssm_parameter.account_type.value
  input_param_deployment_environment = data.aws_ssm_parameter.deployment_environment.value
  input_param_primary_region         = data.aws_ssm_parameter.primary_region.value
}

data "aws_ssm_parameter" "account_name" {
  name     = "/central/account/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "account_type" {
  name     = "/central/account/type"
  provider = aws.parameters
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}
