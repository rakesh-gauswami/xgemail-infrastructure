output "events_rule_eip_rotation_role_arn" {
  value = aws_iam_role.events_rule_eip_rotation_role.arn
}

output "events_rule_eip_rotation_role_name" {
  value = aws_iam_role.events_rule_eip_rotation_role.name
}

output "eip_rotation_lambda_execution_arn" {
  value = aws_iam_role.eip_rotation_lambda_execution_role.arn
}

output "eip_rotation_lambda_execution_role" {
  value = aws_iam_role.eip_rotation_lambda_execution_role.name
}
