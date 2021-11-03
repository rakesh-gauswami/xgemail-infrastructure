
module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/event/rule/multi_eip_rotation_event_rule/arn"
      value       = aws_cloudwatch_event_rule.multi_eip_rotation.arn
      description = "Multi EIP Rotation Event Rule Arn"
    },

    {
      name        = "/central/event/rule/multi_eip_rotation_event_rule/name"
      value       = aws_cloudwatch_event_rule.multi_eip_rotation.id
      description = "Multi EIP Rotation Event Rule Name"
    },

    {
      name        = "/central/ssm/document/multi_eip_rotation_ssm_document/arn"
      value       = aws_ssm_document.multi_eip_rotation.arn
      description = "Multi EIP Rotation SSM Document Arn"
    },

    {
      name        = "/central/ssm/multi_eip_rotation_event_rule/name"
      value       = aws_ssm_document.multi_eip_rotation.id
      description = "Multi EIP Rotation SSM Document Name"
    }
  ]
}