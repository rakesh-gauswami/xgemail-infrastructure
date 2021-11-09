output "ssm_postfix_service_name" {
  value = aws_ssm_document.ssm_postfix_service.name
}

output "ssm_update_hostname_name" {
  value = aws_ssm_document.ssm_update_hostname.name
}

output "zzz_output_parameter_names" {
  value = keys(
    module.output_string_parameters.parameters
  )
}
