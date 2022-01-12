output "mf_elb_o365_ip_sync_lambda_arn" {
  value = aws_lambda_function.mf_elb_o365_ip_sync_lambda.arn
}

output "mf_elb_o365_ip_sync_lambda_name" {
  value = aws_lambda_function.mf_elb_o365_ip_sync_lambda.function_name
}

output "mf_elb_o365_ip_sync_lambda_role_execution_arn" {
  value = aws_iam_role.mf_elb_o365_ip_sync_lambda_execution_role.arn
}

output "mf_elb_o365_ip_sync_lambda_role_execution_name" {
  value = aws_iam_role.mf_elb_o365_ip_sync_lambda_execution_role.name
}

output "mf_elb_o365_ip_sync_scheduled_event_rule_arn" {
  value = aws_cloudwatch_event_rule.mf_elb_o365_ip_sync_scheduled_event_rule.arn
}

output "mf_elb_o365_ip_sync_scheduled_event_rule_name" {
  value = aws_cloudwatch_event_rule.mf_elb_o365_ip_sync_scheduled_event_rule.name
}