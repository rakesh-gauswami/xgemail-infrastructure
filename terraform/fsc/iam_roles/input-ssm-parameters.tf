locals {
  input_param_account_id                          = nonsensitive(data.aws_ssm_parameter.account_id.value)
  input_param_account_type                        = nonsensitive(data.aws_ssm_parameter.account_type.value)
  input_param_deployment_environment              = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_firehose_writer_policy_arn          = nonsensitive(data.aws_ssm_parameter.firehose_writer_policy_arn.value)
  input_param_parent_account_id                   = nonsensitive(data.aws_ssm_parameter.parent_account_id.value)
  input_param_primary_region                      = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_volume_tracker_simpledb_policy_arn  = nonsensitive(data.aws_ssm_parameter.volume_tracker_simpledb_policy_arn.value)
  input_param_vpc_id                              = nonsensitive(data.aws_ssm_parameter.vpc_id.value)
}

data "aws_ssm_parameter" "account_id" {
  name     = "/central/account/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "account_type" {
  name     = "/central/account/type"
  provider = aws.parameters
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "firehose_writer_policy_arn" {
  provider = aws.parameters
  name     = "/central/logging/iam/policies/firehose-writer/arn"
}

data "aws_ssm_parameter" "parent_account_id" {
  name     = "/central/account/parent-account/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}

data "aws_ssm_parameter" "volume_tracker_simpledb_policy_arn" {
  provider = aws.parameters
  name     = "/central/iam/policies/volume-tracker-simpledb/arn"
}

data "aws_ssm_parameter" "vpc_id" {
  provider = aws.parameters
  name     = "/central/vpc/id"
}
