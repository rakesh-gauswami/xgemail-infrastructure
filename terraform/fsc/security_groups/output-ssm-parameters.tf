
module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/sg/base/id"
      value       = aws_security_group.base.id
      description = aws_security_group.base.description
    },

    {
      name        = "/central/sg/efs/policy/id"
      value       = aws_security_group.efs_policy.id
      description = aws_security_group.efs_policy.description
    },

    {
      name        = "/central/sg/efs/postfix-queue/id"
      value       = aws_security_group.efs_postfix_queue.id
      description = aws_security_group.efs_postfix_queue.description
    },

    {
      name        = "/central/sg/logicmonitor/id"
      value       = aws_security_group.logicmonitor.id
      description = aws_security_group.logicmonitor.description
    }
  ]
}
