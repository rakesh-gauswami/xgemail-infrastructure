output "base" {
  value = aws_security_group.base.id
}

output "logicmonitor" {
  value = aws_security_group.logicmonitor.id
}

output "efs_policy" {
  value = aws_security_group.efs_policy.id
}

output "zzz_output_parameter_names" {
  value = keys(
    module.output_string_parameters.parameters
  )
}
