locals {
  input_param_account_name           = nonsensitive(data.aws_ssm_parameter.account_name.value)
  input_param_deployment_environment = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
}

data "aws_ssm_parameter" "account_name" {
  provider = aws.parameters
  name     = "/central/account/name"
}

data "aws_ssm_parameter" "deployment_environment" {
  provider = aws.parameters
  name     = "/central/account/deployment-environment"
}
