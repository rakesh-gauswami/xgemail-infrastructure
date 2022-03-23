output "eip_monitor_lambda_arn" {
  value = aws_lambda_function.eip_monitor_lambda.arn
}

output "eip_monitor_lambda_name" {
  value = aws_lambda_function.eip_monitor_lambda.function_name
}

output "eip_monitor_lambda_role_arn" {
  value = aws_iam_role.eip_monitor_lambda_role.arn
}

output "eip_monitor_lambda_role_name" {
  value = aws_iam_role.eip_monitor_lambda_role.name
}

output "eip_monitor_scheduled_event_rule_arn" {
  value = aws_cloudwatch_event_rule.eip_monitor_scheduled_event_rule.arn
}

output "eip_monitor_scheduled_event_rule_name" {
  value = aws_cloudwatch_event_rule.eip_monitor_scheduled_event_rule.name
}
