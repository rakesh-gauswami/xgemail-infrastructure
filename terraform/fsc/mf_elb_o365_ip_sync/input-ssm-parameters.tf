locals {
  input_param_account_type           = nonsensitive(data.aws_ssm_parameter.account_type.value)
  input_param_deployment_environment = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region         = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_mf_is_security_group   = nonsensitive(data.aws_ssm_parameter.mf_is_security_group_id.value)
  input_param_mf_os_security_group   = nonsensitive(data.aws_ssm_parameter.mf_os_security_group_id.value)
}

data "aws_ssm_parameter" "account_type" {
  name     = "/central/account/type"
  provider = aws.parameters
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "mf_os_security_group_id" {
  name     = "/central/sg/mf/outbound/submit/lb/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "mf_is_security_group_id" {
  name     = "/central/sg/mf/inbound/submit/lb/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}