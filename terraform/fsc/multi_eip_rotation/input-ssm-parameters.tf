locals {
  input_param_primary_region      = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_ssm_postfix_service = nonsensitive(data.aws_ssm_parameter.ssm_postfix_service.value)

  input_param_asg_delta_delivery_lifecycle_hook_launching        = nonsensitive(data.aws_ssm_parameter.asg_delta_delivery_lifecycle_hook_launching.value)
  input_param_asg_delta_xdelivery_lifecycle_hook_launching       = nonsensitive(data.aws_ssm_parameter.asg_delta_xdelivery_lifecycle_hook_launching.value)
  input_param_asg_customer_delivery_lifecycle_hook_launching     = nonsensitive(data.aws_ssm_parameter.asg_customer_delivery_lifecycle_hook_launching.value)
  input_param_asg_customer_xdelivery_lifecycle_hook_launching    = nonsensitive(data.aws_ssm_parameter.asg_customer_xdelivery_lifecycle_hook_launching.value)
  input_param_asg_mf_inbound_delivery_lifecycle_hook_launching   = nonsensitive(data.aws_ssm_parameter.asg_mf_inbound_delivery_lifecycle_hook_launching.value)
  input_param_asg_mf_inbound_xdelivery_lifecycle_hook_launching  = nonsensitive(data.aws_ssm_parameter.asg_mf_inbound_xdelivery_lifecycle_hook_launching.value)
  input_param_asg_mf_outbound_delivery_lifecycle_hook_launching  = nonsensitive(data.aws_ssm_parameter.asg_mf_outbound_delivery_lifecycle_hook_launching.value)
  input_param_asg_mf_outbound_xdelivery_lifecycle_hook_launching = nonsensitive(data.aws_ssm_parameter.asg_mf_outbound_xdelivery_lifecycle_hook_launching.value)
  input_param_asg_internet_delivery_lifecycle_hook_launching     = nonsensitive(data.aws_ssm_parameter.asg_internet_delivery_lifecycle_hook_launching.value)
  input_param_asg_internet_xdelivery_lifecycle_hook_launching    = nonsensitive(data.aws_ssm_parameter.asg_internet_xdelivery_lifecycle_hook_launching.value)
  input_param_asg_risky_delivery_lifecycle_hook_launching        = nonsensitive(data.aws_ssm_parameter.asg_risky_delivery_lifecycle_hook_launching.value)
  input_param_asg_risky_xdelivery_lifecycle_hook_launching       = nonsensitive(data.aws_ssm_parameter.asg_risky_xdelivery_lifecycle_hook_launching.value)
}

data "aws_ssm_parameter" "asg_delta_delivery_lifecycle_hook_launching" {
  name     = "/central/asg/delta-delivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_delta_xdelivery_lifecycle_hook_launching" {
  name     = "/central/asg/delta-xdelivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_customer_delivery_lifecycle_hook_launching" {
  name     = "/central/asg/customer-delivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_customer_xdelivery_lifecycle_hook_launching" {
  name     = "/central/asg/customer-xdelivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_mf_inbound_delivery_lifecycle_hook_launching" {
  name     = "/central/asg/mf-inbound-delivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_mf_inbound_xdelivery_lifecycle_hook_launching" {
  name     = "/central/asg/mf-inbound-xdelivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_mf_outbound_delivery_lifecycle_hook_launching" {
  name     = "/central/asg/mf-outbound-delivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_mf_outbound_xdelivery_lifecycle_hook_launching" {
  name     = "/central/asg/mf-outbound-xdelivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_internet_delivery_lifecycle_hook_launching" {
  name     = "/central/asg/internet-delivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_internet_xdelivery_lifecycle_hook_launching" {
  name     = "/central/asg/internet-xdelivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_risky_delivery_lifecycle_hook_launching" {
  name     = "/central/asg/risky-delivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "asg_risky_xdelivery_lifecycle_hook_launching" {
  name     = "/central/asg/risky-xdelivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "primary_region" {
  name     = "/central/account/primary-region"
  provider = aws.parameters
}

data "aws_ssm_parameter" "ssm_postfix_service" {
  provider = aws.parameters
  name     = "/central/ssm/document/ssm-postfix-service/name"
}
