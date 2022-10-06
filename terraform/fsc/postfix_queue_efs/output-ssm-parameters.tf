
module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/efs/postfix-queue/volume/id"
      value       = aws_efs_file_system.xgemail-postfix-queue-efs-volume.id
      description = "Postfix Queue EFS Volume ID"
    }
  ]
}
