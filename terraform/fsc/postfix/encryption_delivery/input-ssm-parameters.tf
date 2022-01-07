locals {
  input_param_account_type                    = nonsensitive(data.aws_ssm_parameter.account_type.value)
  input_param_deployment_environment          = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region                  = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_sg_base_id                      = nonsensitive(data.aws_ssm_parameter.sg_base_id.value)
  input_param_sg_logicmonitor_id              = nonsensitive(data.aws_ssm_parameter.sg_logicmonitor_id.value)
  input_param_vpc_id                          = nonsensitive(data.aws_ssm_parameter.vpc_id.value)
  input_param_public_subnet_ids               = split(",", nonsensitive(data.aws_ssm_parameter.public_subnet_ids.value))
  input_param_zone_id                         = nonsensitive(data.aws_ssm_parameter.zone_id.value)
  input_param_zone_fqdn                       = nonsensitive(data.aws_ssm_parameter.zone_fqdn.value)
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

data "aws_ssm_parameter" "public_subnet_ids" {
  name     = "/central/vpc/public-subnet-ids"
  provider = aws.parameters
}

data "aws_ssm_parameter" "sg_base_id" {
  provider = aws.parameters

  name = "/central/sg/base/id"
}

data "aws_ssm_parameter" "sg_logicmonitor_id" {
  provider = aws.parameters

  name = "/central/sg/logicmonitor/id"
}

data "aws_ssm_parameter" "zone_fqdn" {
  name     = "/central/account/dns/zone-fqdn"
  provider = aws.parameters
}

data "aws_ssm_parameter" "vpc_id" {
  provider = aws.parameters
  name     = "/central/vpc/id"
}

data "aws_ssm_parameter" "zone_id" {
  name     = "/central/account/dns/zone-id"
  provider = aws.parameters
}
