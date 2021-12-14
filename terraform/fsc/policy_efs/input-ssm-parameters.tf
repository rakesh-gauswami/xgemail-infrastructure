locals {
  input_param_deployment_environment = data.aws_ssm_parameter.deployment_environment.value
  input_param_security_groups        = data.aws_ssm_parameter.security_groups.value
  input_param_subnet_ids             = data.aws_ssm_parameter.subnet_ids.value
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "security_groups" {
  name     = "/central/sg/base/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "subnet_ids" {
  name     = "/central/vpc/private-subnet-ids"
  provider = aws.parameters
}