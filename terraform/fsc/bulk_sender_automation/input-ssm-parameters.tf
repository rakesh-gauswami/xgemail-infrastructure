locals {
  input_param_account_id              = nonsensitive(data.aws_ssm_parameter.account_id.value)
  input_param_primary_region          = nonsensitive(data.aws_ssm_parameter.primary_region.value)
}

data "aws_ssm_parameter" "account_id" {
  name     = "/central/account/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}
