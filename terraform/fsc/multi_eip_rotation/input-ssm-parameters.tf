locals {
  input_param_primary_region          = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_ssm_postfix_service     = nonsensitive(data.aws_ssm_parameter.ssm_postfix_service.value)

  input_param_asg_warmup_delivery_lifecycle_hook_launching         = nonsensitive(data.aws_ssm_parameter.asg_warmup_delivery_lifecycle_hook_launching.value)
  input_param_asg_warmup_xdelivery_lifecycle_hook_launching        = nonsensitive(data.aws_ssm_parameter.asg_warmup_xdelivery_lifecycle_hook_launching.value)
}

data "aws_ssm_parameter" "asg_warmup_delivery_lifecycle_hook_launching" {
  name     = "/central/asg/warmup-delivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_warmup_xdelivery_lifecycle_hook_launching" {
  name     = "/central/asg/warmup-xdelivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}

data "aws_ssm_parameter" "ssm_postfix_service" {
  provider = aws.parameters
  name = "/central/ssm/document/ssm-postfix-service/name"
}
