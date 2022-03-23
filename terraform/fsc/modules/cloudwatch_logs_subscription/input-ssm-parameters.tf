locals {
  input_param_cloudwatch_logs_firehose_role       = data.aws_ssm_parameter.cloudwatch_logs_firehose_role.value
  input_param_deployment_environment              = data.aws_ssm_parameter.deployment_environment.value
  input_param_log_shipping_firehose_stream        = data.aws_ssm_parameter.log_shipping_firehose_stream.value
  input_param_primary_region                      = data.aws_ssm_parameter.primary_region.value
}

data "aws_ssm_parameter" "cloudwatch_logs_firehose_role" {
  name     = "/central/logging/iam/roles/cloudwatch-logs-firehose-role/arn"
  provider = aws.parameters
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "log_shipping_firehose_stream" {
  name     = "/central/logging/firehose-stream/arn"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}
