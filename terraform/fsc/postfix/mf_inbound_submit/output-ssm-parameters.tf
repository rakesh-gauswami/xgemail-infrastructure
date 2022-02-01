module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/sg/mf/inbound/submit/lb/id"
      value       = aws_security_group.security_group_lb.id
      description = "Security group controlling access to ${local.security_group_name_lb}."
    }
  ]
}