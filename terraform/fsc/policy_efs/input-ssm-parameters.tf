locals {
  input_param_deployment_environment = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_security_group         = nonsensitive(data.aws_ssm_parameter.security_group.value)
  input_param_subnet_ids             = nonsensitive(data.aws_ssm_parameter.subnet_ids.value)
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "security_group" {
  name     = "/central/vpc/default-security-group-id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "subnet_ids" {
  name     = "/central/vpc/private-subnet-ids"
  provider = aws.parameters
}