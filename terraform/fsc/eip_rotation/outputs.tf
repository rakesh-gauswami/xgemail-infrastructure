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

output "eip_rotation_ssm_execution_arn" {
  value = aws_ssm_document.eip_rotation.arn
}

output "eip_rotation_lambda_ssm_execution_name" {
  value = aws_ssm_document.eip_rotation.name
}