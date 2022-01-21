output "security_group_lb" {
  value = aws_security_group.security_group_lb.id
}

output "security_group_ec2" {
  value = aws_security_group.security_group_ec2.id
}

output "zzz_output_parameter_names" {
  value = keys(
  module.output_string_parameters.parameters
  )
}