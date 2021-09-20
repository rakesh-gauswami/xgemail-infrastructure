resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  name              = "${var.function_name}-cw-logs-to-firehose-subscription"
  log_group_name    = "/aws/lambda/${var.function_name}"
  filter_pattern    = var.cloudwatch_filter_pattern
  destination_arn   = local.input_param_log_shipping_firehose_stream
  distribution      = "ByLogStream"
  role_arn          = local.input_param_cloudwatch_logs_firehose_role
}
