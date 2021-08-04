
resource "aws_ssm_parameter" "parameters" {
  for_each = { for val in var.parameters :

    val.name => {
      value       = val.value
      description = val.description
    }
  }

  name        = each.key
  type        = "String"
  value       = each.value.value
  description = each.value.description

  overwrite = true

  tags = { Name = each.key }
}
