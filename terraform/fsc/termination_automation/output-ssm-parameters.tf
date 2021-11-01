module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/event/rule/termination_automation_event_rule/arn"
      value       = aws_cloudwatch_event_rule.termination_automation.arn
      description = "Termination Automation Events Rule Arn"
    },

    {
      name        = "/central/event/rule/termination_automation_event_rule/name"
      value       = aws_cloudwatch_event_rule.termination_automation.id
      description = "Termination Automation Events Rule Name"
    },

    {
      name        = "/central/ssm/document/termination_automation_ssm_document/arn"
      value       = aws_ssm_document.termination_automation.arn
      description = "Termination Automation SSM Document Arn"
    },

    {
      name        = "/central/ssm/termination_automation_event_rule/name"
      value       = aws_ssm_document.termination_automation.id
      description = "Termination Automation SSM Document Name"
    }
  ]
}
