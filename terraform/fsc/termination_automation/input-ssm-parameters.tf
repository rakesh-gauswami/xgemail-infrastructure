locals {
  input_param_account_type            = data.aws_ssm_parameter.account_type.value
  input_param_alarm_topic_arn         = data.aws_ssm_parameter.alarm_topic_arn.value
  input_param_deployment_environment  = data.aws_ssm_parameter.deployment_environment.value
  input_param_primary_region          = data.aws_ssm_parameter.primary_region.value
}

data "aws_ssm_parameter" "account_type" {
  name     = "/central/account/type"
  provider = aws.parameters
}

data "aws_ssm_parameter" "alarm_topic_arn" {
  name     = "/central/sns/alarm-topic/arn"
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
