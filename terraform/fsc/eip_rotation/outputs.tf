output "eip_rotation_lambda_arn" {
  value = aws_lambda_function.eip_rotation_lambda.arn
}

output "eip_rotation_lambda_name" {
  value = aws_lambda_function.eip_rotation_lambda.function_name
}

output "events_rule_eip_rotation_role_arn" {
  value = aws_iam_role.events_rule_eip_rotation_role.arn
}

output "events_rule_eip_rotation_role_name" {
  value = aws_iam_role.events_rule_eip_rotation_role.name
}

output "eip_rotation_lambda_execution_arn" {
  value = aws_iam_role.eip_rotation_lambda_execution_role.arn
}

output "eip_rotation_lambda_execution_role_name" {
  value = aws_iam_role.eip_rotation_lambda_execution_role.name
}

output "eip_rotation_lambda_ssm_execution_name" {
  value = aws_ssm_document.eip_rotation.name
}

output "eip_rotation_lifecycle_event_rule_arn" {
  value = aws_cloudwatch_event_rule.eip_rotation_lifecycle_event_rule.arn
}

output "eip_rotation_lifecycle_event_rule_name" {
  value = aws_cloudwatch_event_rule.eip_rotation_lifecycle_event_rule.name
}

output "eip_rotation_scheduled_event_rule_arn" {
  value = aws_cloudwatch_event_rule.eip_rotation_scheduled_event_rule.arn
}

output "eip_rotation_scheduled_event_rule_name" {
  value = aws_cloudwatch_event_rule.eip_rotation_scheduled_event_rule.name
}
