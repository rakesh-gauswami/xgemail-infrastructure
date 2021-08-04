output "parameters" {
  value = {for parameter in aws_ssm_parameter.parameters:
    parameter.name => {
      name        = parameter.name
      type        = parameter.type
      description = parameter.description
      value       = nonsensitive(parameter.value)
    }
  }
}
