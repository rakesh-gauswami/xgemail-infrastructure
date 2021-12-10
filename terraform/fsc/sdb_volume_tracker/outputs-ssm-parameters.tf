module "output_string_parameters" {
  source = "../modules/output_string_parameters"
  providers = {
    aws = aws.parameters
  }
  parameters = [
    {
      name        = "/central/simpledb/domain/volume-tracker/name"
      value       = aws_simpledb_domain.volume_tracker.name
      description = "Volume Tracker SimpleDb Domain name"
    },
    {
      name        = "/central/simpledb/domain/volume-tracker/id"
      value       = aws_simpledb_domain.volume_tracker.id
      description = "Volume Tracker SimpleDb Domain id"
    }
  ]
}
