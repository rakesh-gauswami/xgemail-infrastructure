locals {
  input_param_account_type            = nonsensitive(data.aws_ssm_parameter.account_type.value)
  input_param_deployment_environment  = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region          = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_ssm_postfix_service     = nonsensitive(data.aws_ssm_parameter.ssm_postfix_service.value)
  input_param_ssm_update_hostname     = nonsensitive(data.aws_ssm_parameter.ssm_update_hostname.value)
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

data "aws_ssm_parameter" "ssm_postfix_service" {
  provider = aws.parameters
  name = "/central/ssm/document/ssm_postfix_service/name"
}

data "aws_ssm_parameter" "ssm_update_hostname" {
  provider = aws.parameters
  name = "/central/ssm/document/ssm_update_hostname/name"
}