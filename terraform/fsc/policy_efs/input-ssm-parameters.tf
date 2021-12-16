locals {
  input_param_deployment_environment = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_subnet_ids             = split(",", nonsensitive(data.aws_ssm_parameter.subnet_ids.value))
  input_param_security_groups        = nonsensitive(data.aws_ssm_parameter.security_groups.value)
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "subnet_ids" {
  name     = "/central/vpc/private-subnet-ids"
  provider = aws.parameters
}

data "aws_ssm_parameter" "security_groups" {
  name     = "/central/sg/efs/policy/id"
  provider = aws.parameters
}

