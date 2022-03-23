locals {
  efs_policy_sg_name  = "efs-policy"
}

resource "aws_security_group" "efs_policy" {
  name        = local.efs_policy_sg_name
  description = "Controls access to the policy EFS mount targets"
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.efs_policy_sg_name }
}
