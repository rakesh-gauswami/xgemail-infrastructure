module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/ssm/document/ssm_postfix_service/name"
      value       = aws_ssm_document.ssm_postfix_service.name
      description = "Postfix Service SSM Document Name"
    },

    {
      name        = "/central/ssm/document/ssm_update_hostname/name"
      value       = aws_ssm_document.ssm_update_hostname.name
      description = "Update Hostname SSM Document Name"
    }
  ]
}
