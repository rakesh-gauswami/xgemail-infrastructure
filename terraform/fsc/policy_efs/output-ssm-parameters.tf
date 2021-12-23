
module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/efs/policy/volume/id"
      value       = aws_efs_file_system.xgemail-policy-efs-volume.id
      description = "Policy EFS Volume ID"
    }
  ]
}
