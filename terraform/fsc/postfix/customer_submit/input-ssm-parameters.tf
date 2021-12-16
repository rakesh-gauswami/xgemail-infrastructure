locals {
  input_param_availability_zones            = nonsensitive(data.aws_ssm_parameter.availability_zones.value)
  input_param_account_type            = nonsensitive(data.aws_ssm_parameter.account_type.value)
  input_param_deployment_environment  = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region          = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_public_subnet_ids       = nonsensitive(data.aws_ssm_parameter.public_subnet_ids.value)
  input_param_sg_base_id              = nonsensitive(data.aws_ssm_parameter.sg_base_id.value)
  input_param_sg_logicmonitor_id      = nonsensitive(data.aws_ssm_parameter.sg_logicmonitor_id.value)
  input_param_sg_efs_policy_id        = nonsensitive(data.aws_ssm_parameter.sg_efs_policy_id.value)
  input_param_vpc_id                  = nonsensitive(data.aws_ssm_parameter.vpc_id.value)
  input_param_zone_fqdn               = nonsensitive(data.aws_ssm_parameter.zone_fqdn.value)
  input_param_zone_id                 = nonsensitive(data.aws_ssm_parameter.zone_id.value)
  input_param_alarm_topic_arn         = nonsensitive(data.aws_ssm_parameter.alarm_topic_arn.value)
  input_param_lifecycle_topic_arn         = nonsensitive(data.aws_ssm_parameter.lifecycle_topic_arn.value)


  HostAlarmTopicARN:              "{{sns.arn_prefix}}{{sns.alarm_sns_topic}}"
   Subnets:                        "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.VpcZoneIdentifiersPublic}}"



}


data "aws_ssm_parameter" "availability_zones" {
  name     = "/central/vpc/availability-zones"
  provider = aws.parameters
}

data "aws_ssm_parameter" "account_type" {
  name     = "/central/account/type"
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

data "aws_ssm_parameter" "public_subnet_ids" {
  name     = "/central/vpc/public-subnet-ids"
  provider = aws.parameters
}

data "aws_ssm_parameter" "sg_base_id" {
  provider = aws.parameters

  name = "/central/sg/base/id"
}

data "aws_ssm_parameter" "sg_efs_policy_id" {
  provider = aws.parameters

  name = "/central/sg/efs/policy/id"
}

data "aws_ssm_parameter" "sg_logicmonitor_id" {
  provider = aws.parameters

  name = "/central/sg/logicmonitor/id"
}

data "aws_ssm_parameter" "vpc_id" {
  provider = aws.parameters
  name     = "/central/vpc/id"
}

data "aws_ssm_parameter" "zone_fqdn" {
  provider = aws.parameters
  name     = "/central/account/dns/zone-fqdn"
}

data "aws_ssm_parameter" "zone_id" {
  provider = aws.parameters
  name     = "/central/account/dns/zone-id"
}

data "aws_ssm_parameter" "terminating_lifecycle_hook_name" {
  provider = aws.parameters
  name     = "/central/asg/customer-submit/lifecycle-hook/terminating/name"
}

data "aws_ssm_parameter" "alarm_topic_arn" {
  provider = aws.parameters
  name     = "/central/sns/alarm-topic/arn"
}

data "aws_ssm_parameter" "lifecycle_topic_arn" {
  provider = aws.parameters
  name     = "/central/sns/lifecycle-topic/arn"
}

data "aws_ssm_parameter" "public_subnet_ids" {
  provider = aws.parameters
  name     = "/central/vpc/public-subnet-ids"
}
