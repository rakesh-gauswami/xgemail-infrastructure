module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/event/rule/eip_rotation_event_rule/arn"
      value       = aws_cloudwatch_event_rule.eip_rotation.arn
      description = "EIP Rotation Events Rule Arn"
    },

    {
      name        = "/central/event/rule/eip_rotation_event_rule/name"
      value       = aws_cloudwatch_event_rule.eip_rotation.id
      description = "EIP Rotation Events Rule Name"
    },

    {
      name        = "/central/lambda/eip_rotation_lambda_function/arn"
      value       = aws_lambda_function.xgemail_eip_rotation.arn
      description = "EIP Rotation Lambda Arn"
    },

    {
      name        = "/central/lambda/eip_rotation_event_rule/name"
      value       = aws_lambda_function.xgemail_eip_rotation.id
      description = "EIP Rotation Lambda Name"
    }
  ]
}