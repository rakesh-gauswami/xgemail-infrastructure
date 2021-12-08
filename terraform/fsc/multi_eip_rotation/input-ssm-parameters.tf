locals {
  input_param_primary_region          = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_ssm_postfix_service     = nonsensitive(data.aws_ssm_parameter.ssm_postfix_service.value)
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}

data "aws_ssm_parameter" "ssm_postfix_service" {
  provider = aws.parameters
  name = "/central/ssm/document/ssm_postfix_service/name"
}