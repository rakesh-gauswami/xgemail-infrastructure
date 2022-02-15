
module "output_string_parameters" {
  source = "../../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/sg/${local.instance_type}/id"
      value       = aws_security_group.security_group_ec2.id
      description = "${local.instance_type} Instance Security Group ID"
    }
  ]
}
