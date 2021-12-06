output "multi_eip_rotation_lambda_arn" {
  value = aws_lambda_function.multi_eip_rotation_lambda.arn
}

output "multi_eip_rotation_lambda_name" {
  value = aws_lambda_function.multi_eip_rotation_lambda.function_name
}

output "multi_eip_rotation_lambda_execution_role_arn" {
  value = aws_iam_role.multi_eip_rotation_lambda_execution_role.arn
}

output "multi_eip_rotation_lambda_execution_role_name" {
  value = aws_iam_role.multi_eip_rotation_lambda_execution_role.name
}

output "multi_eip_rotation_ssm_arn" {
  value = aws_ssm_document.multi_eip_rotation.arn
}

output "multi_eip_rotation_ssm_name" {
  value = aws_ssm_document.multi_eip_rotation.name
}

output "multi_eip_rotation_ssm_automation_role_arn" {
  value = aws_iam_role.multi_eip_rotation_ssm_automation_role.arn
}

output "multi_eip_rotation_ssm_automation_role_name" {
  value = aws_iam_role.multi_eip_rotation_ssm_automation_role.name
}

output "multi_eip_lifecycle_event_rule_arn" {
  value = aws_cloudwatch_event_rule.multi_eip_lifecycle_event_rule.arn
}

output "multi_eip_lifecycle_event_rule_name" {
  value = aws_cloudwatch_event_rule.multi_eip_lifecycle_event_rule.name
}

output "multi_eip_rotation_scheduled_event_rule_arn" {
  value = aws_cloudwatch_event_rule.multi_eip_rotation_scheduled_event_rule.arn
}

output "multi_eip_rotation_scheduled_event_rule_name" {
  value = aws_cloudwatch_event_rule.multi_eip_rotation_scheduled_event_rule.name
}

output "zzz_output_parameter_names" {
  value = keys(
    module.output_string_parameters.parameters
  )
}