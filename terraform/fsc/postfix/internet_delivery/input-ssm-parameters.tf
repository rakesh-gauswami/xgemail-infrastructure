locals {
  input_param_account_name                = nonsensitive(data.aws_ssm_parameter.account_name.value)
  input_param_account_type                = nonsensitive(data.aws_ssm_parameter.account_type.value)
  input_param_autoscaling_role_arn        = nonsensitive(data.aws_ssm_parameter.autoscaling_role_arn.value)
  input_param_availability_zones          = nonsensitive(data.aws_ssm_parameter.availability_zones.value)
  input_param_cloud_templates_bucket_name = nonsensitive(data.aws_ssm_parameter.cloud_templates_bucket_name.value)
  input_param_deployment_environment      = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_policy_efs_volume_id        = nonsensitive(data.aws_ssm_parameter.policy_efs_volume_id.value)
  input_param_primary_region              = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_public_subnet_ids           = nonsensitive(data.aws_ssm_parameter.public_subnet_ids.value)
  input_param_sg_base_id                  = nonsensitive(data.aws_ssm_parameter.sg_base_id.value)
  input_param_sg_logicmonitor_id          = nonsensitive(data.aws_ssm_parameter.sg_logicmonitor_id.value)
  input_param_sg_efs_policy_id            = nonsensitive(data.aws_ssm_parameter.sg_efs_policy_id.value)
  input_param_vpc_id                      = nonsensitive(data.aws_ssm_parameter.vpc_id.value)
  input_param_zone_fqdn                   = nonsensitive(data.aws_ssm_parameter.zone_fqdn.value)
  input_param_zone_id                     = nonsensitive(data.aws_ssm_parameter.zone_id.value)
  input_param_alarm_topic_arn             = nonsensitive(data.aws_ssm_parameter.alarm_topic_arn.value)
  input_param_lifecycle_topic_arn         = nonsensitive(data.aws_ssm_parameter.lifecycle_topic_arn.value)
  input_param_lifecycle_hook_launching    = nonsensitive(data.aws_ssm_parameter.lifecycle_hook_launching_name.value)
  input_param_lifecycle_hook_terminating  = nonsensitive(data.aws_ssm_parameter.lifecycle_topic_arn.value)
  input_param_iam_instance_profile_arn    = nonsensitive(data.aws_ssm_parameter.iam_instance_profile_arn.value)
}

data "aws_ssm_parameter" "account_name" {
  name     = "/central/account/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "account_type" {
  name     = "/central/account/type"
  provider = aws.parameters
}

data "aws_ssm_parameter" "autoscaling_role_arn" {
  name     = "/central/iam/roles/autoscaling/arn"
  provider = aws.parameters
}

data "aws_ssm_parameter" "availability_zones" {
  name     = "/central/vpc/availability-zones"
  provider = aws.parameters
}

data "aws_ssm_parameter" "cloud_templates_bucket_name" {
  name     = "/central/s3/cloud-${local.input_param_account_name}-templates/name"
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

data "aws_ssm_parameter" "policy_efs_volume_id" {
  name     = "/central/efs/policy/volume/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "public_subnet_ids" {
  name     = "/central/vpc/public-subnet-ids"
  provider = aws.parameters
}

data "aws_ssm_parameter" "sg_base_id" {
  name     = "/central/sg/base/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "sg_efs_policy_id" {
  name     = "/central/sg/efs/policy/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "sg_logicmonitor_id" {
  name     = "/central/sg/logicmonitor/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "vpc_id" {
  name     = "/central/vpc/id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "zone_fqdn" {
  name     = "/central/account/dns/zone-fqdn"
  provider = aws.parameters
}

data "aws_ssm_parameter" "zone_id" {
  name     = "/central/account/dns/zone-id"
  provider = aws.parameters
}

data "aws_ssm_parameter" "lifecycle_hook_launching_name" {
  name     = "/central/asg/internet-delivery/lifecycle-hook/launching/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "lifecycle_hook_terminating_name" {
  name     = "/central/asg/${local.instance_type}/lifecycle-hook/terminating/name"
  provider = aws.parameters
}

data "aws_ssm_parameter" "alarm_topic_arn" {
  name     = "/central/sns/alarm-topic/arn"
  provider = aws.parameters
}

data "aws_ssm_parameter" "lifecycle_topic_arn" {
  name     = "/central/sns/lifecycle-topic/arn"
  provider = aws.parameters
}

data "aws_ssm_parameter" "iam_instance_profile_arn" {
  name     = "/central/iam/profiles/${local.instance_type}-instance/arn"
  provider = aws.parameters
}