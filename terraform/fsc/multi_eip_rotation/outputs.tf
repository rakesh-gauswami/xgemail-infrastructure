output "multi_eip_rotation_lambda_execution_role_arn" {
  value = aws_iam_role.multi_eip_rotation_lambda_execution_role.arn
}

output "multi_eip_rotation_lambda_execution_role_name" {
  value = aws_iam_role.multi_eip_rotation_lambda_execution_role.name
}

output "multi_eip_rotation_ssm_automation_role_arn" {
  value = aws_iam_role.multi_eip_rotation_ssm_automation_role.arn
}

output "multi_eip_rotation_ssm_automation_role_name" {
  value = aws_iam_role.multi_eip_rotation_ssm_automation_role.name
}

output "zzz_output_parameter_names" {
  value = keys(
    module.output_string_parameters.parameters
  )
}