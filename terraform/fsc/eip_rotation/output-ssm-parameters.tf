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
      value       = aws_lambda_function.eip_rotation.arn
      description = "EIP Rotation Lambda Arn"
    },

    {
      name        = "/central/lambda/eip_rotation_event_rule/name"
      value       = aws_lambda_function.eip_rotation.id
      description = "EIP Rotation Lambda Name"
    },

    {
      name        = "/central/ssm/document/eip_rotation_ssm_document/arn"
      value       = aws_ssm_document.eip_rotation.arn
      description = "EIP Rotation SSM Document Arn"
    },

    {
      name        = "/central/ssm/eip_rotation_event_rule/name"
      value       = aws_ssm_document.eip_rotation.id
      description = "EIP Rotation SSM Document Name"
    }
  ]
}