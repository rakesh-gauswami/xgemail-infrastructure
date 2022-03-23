locals {
  input_param_deployment_environment = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region         = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_vpc_id                 = nonsensitive(data.aws_ssm_parameter.vpc_id.value)
}

data "aws_ssm_parameter" "deployment_environment" {
  provider = aws.parameters

  name = "/central/account/deployment-environment"
}

data "aws_ssm_parameter" "primary_region" {
  provider = aws.parameters

  name = "/central/account/primary-region"
}

data "aws_ssm_parameter" "vpc_id" {
  provider = aws.parameters

  name = "/central/vpc/id"
}
