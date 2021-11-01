output "events_rule_ssm_automation_role_arn" {
  value = aws_iam_role.events_rule_ssm_automation_role.arn
}

output "events_rule_ssm_automation_role_name" {
  value = aws_iam_role.events_rule_ssm_automation_role.name
}

output "termination_automation_role_arn" {
  value = aws_iam_role.termination_automation_role.arn
}

output "termination_automation_role_name" {
  value = aws_iam_role.termination_automation_role.name
}

output "zzz_output_parameter_names" {
  value = keys(
    module.output_string_parameters.parameters
  )
}
