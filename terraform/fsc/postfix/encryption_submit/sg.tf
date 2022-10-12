locals {
  cidr_block_world       = "0.0.0.0/0"
  efs_tcp_port           = 2049
  ntp_udp_port           = 123
  smtp_tcp_port          = 25
  security_group_name_lb = "${local.instance_type}-lb"
}

data "aws_security_group" "base" {
  id = local.input_param_sg_base_id
}

data "aws_security_group" "efs_postfix_queue" {
  id = local.input_param_sg_efs_postfix_queue_id
}

resource "aws_security_group" "security_group_lb" {
  name        = local.security_group_name_lb
  description = "Security group controlling access to ${local.security_group_name_lb}."
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.security_group_name_lb }
}

resource "aws_security_group_rule" "lb_ingress_smtp" {
  type              = "ingress"
  cidr_blocks       = ["52.211.15.91/32", "52.211.67.90/32", "52.209.4.238/32", "52.209.219.173/32", "52.19.12.201/32", "52.209.235.6/32", "18.196.89.248/32", "18.184.91.171/32", "3.121.221.91/32", "3.121.255.216/32", "13.58.136.73/32", "18.191.85.155/32", "18.223.14.153/32", "18.217.225.34/32", "198.144.101.0/24", "208.70.208.0/22", "69.10.229.170/32", "99.79.129.161/32", "99.79.14.156/32", "52.60.50.12/32", "35.182.204.165/32", "35.183.216.19/32", "15.222.85.71/32", "35.182.43.32/32"]
  from_port         = local.smtp_tcp_port
  to_port           = local.smtp_tcp_port
  protocol          = "tcp"
  security_group_id = aws_security_group.security_group_lb.id
}

resource "aws_security_group_rule" "lb_egress_world" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.security_group_lb.id
  cidr_blocks       = [local.cidr_block_world]
}

resource "aws_security_group" "security_group_ec2" {
  name        = local.instance_type
  description = "Security group controlling access to ${local.instance_type}."
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.instance_type }
}

resource "aws_security_group_rule" "ec2_ingress_lb_smtp" {
  type                     = "ingress"
  from_port                = local.smtp_tcp_port
  to_port                  = local.smtp_tcp_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.security_group_ec2.id
  source_security_group_id = aws_security_group.security_group_lb.id
}

resource "aws_security_group_rule" "ec2_egress_world" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.security_group_ec2.id
  cidr_blocks       = [local.cidr_block_world]
}

resource "aws_security_group_rule" "efs_postfix_queue_ingress_tcp" {
  type                     = "ingress"
  from_port                = local.efs_tcp_port
  to_port                  = local.efs_tcp_port
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.efs_postfix_queue.id
  source_security_group_id = aws_security_group.security_group_ec2.id
}