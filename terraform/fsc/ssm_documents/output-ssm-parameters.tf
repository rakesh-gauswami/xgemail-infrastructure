module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [

    {
      name        = "/central/ssm/document/ssm-postconf-command/name"
      value       = aws_ssm_document.ssm_postconf_command.name
      description = "Postconf Command SSM Document Name"
    },

    {
      name        = "/central/ssm/document/ssm-postfix-service/name"
      value       = aws_ssm_document.ssm_postfix_service.name
      description = "Postfix Service SSM Document Name"
    },

    {
      name        = "/central/ssm/document/ssm-update-hostname/name"
      value       = aws_ssm_document.ssm_update_hostname.name
      description = "Update Hostname SSM Document Name"
    },

    {
      name        = "/central/ssm/document/tag-instance-automation/name"
      value       = aws_ssm_document.tag_instance_automation.name
      description = "Tag Instance Automation SSM Document Name"
    }
  ]
}
