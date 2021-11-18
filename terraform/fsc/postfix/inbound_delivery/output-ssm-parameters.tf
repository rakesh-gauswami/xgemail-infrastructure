
module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/sg/inbound/delivery/ec2/id"
      value       = aws_security_group.security_group_ec2.id
      description = aws_security_group.security_group_ec2.description
    }
  ]
}
