output "bulk_sender_automation_name" {
  value = aws_ssm_document.bulk_sender_automation.name
}

output "bulk_sender_automation_role_arn" {
  value = aws_iam_role.bulk_sender_automation_role.arn
}

output "bulk_sender_automation_role_name" {
  value = aws_iam_role.bulk_sender_automation_role.id
}

output "postfix_sxl_update_automation_name" {
  value = aws_ssm_document.postfix_sxl_update_automation.name
}

output "postfix_sxl_update_automation_role_arn" {
  value = aws_iam_role.postfix_sxl_update_automation_role.arn
}

output "postfix_sxl_update_automation_role_name" {
  value = aws_iam_role.postfix_sxl_update_automation_role.id
}

output "session_manager_runshell_name" {
  value = aws_ssm_document.session_manager_runshell.name
}

output "ssm_postconf_command_name" {
  value = aws_ssm_document.ssm_postconf_command.name
}

output "ssm_postfix_service_name" {
  value = aws_ssm_document.ssm_postfix_service.name
}

output "ssm_update_hostname_name" {
  value = aws_ssm_document.ssm_update_hostname.name
}

output "sxl_instance_update_automation_name" {
  value = aws_ssm_document.sxl_instance_update_automation.name
}

output "tag_instance_automation_name" {
  value = aws_ssm_document.tag_instance_automation.name
}

output "terminate_asg_instance_automation_name" {
  value = aws_ssm_document.terminate_asg_instance_automation.name
}

output "terminate_asg_instance_automation_role_arn" {
  value = aws_iam_role.terminate_asg_instance_automation_role.arn
}

output "terminate_asg_instance_automation_role_name" {
  value = aws_iam_role.terminate_asg_instance_automation_role.id
}

output "zzz_output_parameter_names" {
  value = keys(
    module.output_string_parameters.parameters
  )
}
