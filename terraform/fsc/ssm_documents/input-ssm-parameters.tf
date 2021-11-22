locals {
  input_param_primary_region          = data.aws_ssm_parameter.primary_region.value
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}
