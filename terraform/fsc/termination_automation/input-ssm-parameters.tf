locals {
  input_param_account_type            = nonsensitive(data.aws_ssm_parameter.account_type.value)
  input_param_alarm_topic_arn         = nonsensitive(data.aws_ssm_parameter.alarm_topic_arn.value)
  input_param_deployment_environment  = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region          = nonsensitive(data.aws_ssm_parameter.primary_region.value)

  input_param_asg_delta_delivery_lifecycle_hook_terminating       = nonsensitive(data.aws_ssm_parameter.asg_delta_delivery_lifecycle_hook_terminating.value)
  input_param_asg_encryption_delivery_lifecycle_hook_terminating  = nonsensitive(data.aws_ssm_parameter.asg_encryption_delivery_lifecycle_hook_terminating.value)
  input_param_asg_encryption_submit_lifecycle_hook_terminating    = nonsensitive(data.aws_ssm_parameter.asg_encryption_submit_lifecycle_hook_terminating.value)
  input_param_asg_customer_delivery_lifecycle_hook_terminating    = nonsensitive(data.aws_ssm_parameter.asg_customer_delivery_lifecycle_hook_terminating.value)
  input_param_asg_internet_submit_lifecycle_hook_terminating      = nonsensitive(data.aws_ssm_parameter.asg_internet_submit_lifecycle_hook_terminating.value)
  input_param_asg_mf_inbound_delivery_lifecycle_hook_terminating  = nonsensitive(data.aws_ssm_parameter.asg_mf_inbound_delivery_lifecycle_hook_terminating.value)
  input_param_asg_mf_inbound_submit_lifecycle_hook_terminating    = nonsensitive(data.aws_ssm_parameter.asg_mf_inbound_submit_lifecycle_hook_terminating.value)
  input_param_asg_mf_outbound_delivery_lifecycle_hook_terminating = nonsensitive(data.aws_ssm_parameter.asg_mf_outbound_delivery_lifecycle_hook_terminating.value)
  input_param_asg_mf_outbound_submit_lifecycle_hook_terminating   = nonsensitive(data.aws_ssm_parameter.asg_mf_outbound_submit_lifecycle_hook_terminating.value)
  input_param_asg_internet_delivery_lifecycle_hook_terminating    = nonsensitive(data.aws_ssm_parameter.asg_internet_delivery_lifecycle_hook_terminating.value)
  input_param_asg_customer_submit_lifecycle_hook_terminating      = nonsensitive(data.aws_ssm_parameter.asg_customer_submit_lifecycle_hook_terminating.value)
  input_param_asg_risky_delivery_lifecycle_hook_terminating       = nonsensitive(data.aws_ssm_parameter.asg_risky_delivery_lifecycle_hook_terminating.value)
  input_param_asg_warmup_delivery_lifecycle_hook_terminating      = nonsensitive(data.aws_ssm_parameter.asg_warmup_delivery_lifecycle_hook_terminating.value)
}

data "aws_ssm_parameter" "account_type" {
  name     = "/central/account/type"
  provider = aws.parameters
}

data "aws_ssm_parameter" "alarm_topic_arn" {
  name     = "/central/sns/alarm-topic/arn"
  provider = aws.parameters
}

data "aws_ssm_parameter" "deployment_environment" {
  name     = "/central/account/deployment-environment"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_instances_lifecycle_hook_terminating" {
  name     = "/central/asg/instances/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_delta_delivery_lifecycle_hook_terminating"{
  name     = "/central/asg/delta-delivery/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_encryption_delivery_lifecycle_hook_terminating"{
  name     = "/central/asg/encryption-delivery/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_encryption_submit_lifecycle_hook_terminating"{
  name     = "/central/asg/encryption-submit/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_customer_delivery_lifecycle_hook_terminating" {
  name     = "/central/asg/customer-delivery/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_internet_submit_lifecycle_hook_terminating" {
  name     = "/central/asg/internet-submit/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_mf_inbound_delivery_lifecycle_hook_terminating" {
  name     = "/central/asg/mf-inbound-delivery/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_mf_inbound_submit_lifecycle_hook_terminating" {
  name     = "/central/asg/mf-inbound-submit/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_mf_outbound_delivery_lifecycle_hook_terminating" {
  name     = "/central/asg/mf-outbound-delivery/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_mf_outbound_submit_lifecycle_hook_terminating" {
  name     = "/central/asg/mf-outbound-submit/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_internet_delivery_lifecycle_hook_terminating" {
  name     = "/central/asg/internet-delivery/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_customer_submit_lifecycle_hook_terminating" {
  name     = "/central/asg/customer-submit/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_risky_delivery_lifecycle_hook_terminating" {
  name     = "/central/asg/risky-delivery/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_warmup_delivery_lifecycle_hook_terminating" {
  name     = "/central/asg/warmup-delivery/lifecycle-hook/terminating/name"
  provider = aws.parameters
}
