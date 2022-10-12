locals {
  efs_policy_sg_name  = "efs-policy"
  efs_postfix_queue_sg_name = "efs-postfix-queue"
}

resource "aws_security_group" "efs_policy" {
  name        = local.efs_policy_sg_name
  description = "Controls access to the policy EFS mount targets"
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.efs_policy_sg_name }
}

resource "aws_security_group" "efs_postfix_queue" {
  name        = local.efs_postfix_queue_sg_name
  description = "Controls access to the postfix queue EFS mount targets"
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.efs_postfix_queue_sg_name }
}