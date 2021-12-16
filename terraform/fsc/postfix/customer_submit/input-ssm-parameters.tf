locals {
  input_param_account_type            = nonsensitive(data.aws_ssm_parameter.account_type.value)
  input_param_deployment_environment  = nonsensitive(data.aws_ssm_parameter.deployment_environment.value)
  input_param_primary_region          = nonsensitive(data.aws_ssm_parameter.primary_region.value)
  input_param_public_subnet_ids       = nonsensitive(data.aws_ssm_parameter.public_subnet_ids.value)
  input_param_sg_base_id              = nonsensitive(data.aws_ssm_parameter.sg_base_id.value)
  input_param_sg_logicmonitor_id      = nonsensitive(data.aws_ssm_parameter.sg_logicmonitor_id.value)
  input_param_sg_efs_policy_id        = nonsensitive(data.aws_ssm_parameter.sg_efs_policy_id.value)
  input_param_vpc_id                  = nonsensitive(data.aws_ssm_parameter.vpc_id.value)
  HostAlarmTopicARN:              "{{sns.arn_prefix}}{{sns.alarm_sns_topic}}"
   Subnets:                        "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.VpcZoneIdentifiersPublic}}"
      Vpc:                            "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.Vpc}}"


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
