locals {
  cidr_block_world        = "0.0.0.0/0"
  ntp_udp_port            = 123
  smtp_tcp_port           = 25
  smtptls_tcp_port        = 587
  snmp_port               = 161
  snmp_trap_port          = 162
  security_group_name_lb  = "${local.instance_type}-lb"
}

data "aws_security_group" "base" {
  id = local.input_param_sg_base_id
}

data "aws_security_group" "logicmonitor" {
  id = local.input_param_sg_logicmonitor_id
}

resource "aws_security_group" "security_group_lb" {
  name        = local.security_group_name_lb
  description = "Security group controlling access to ${local.security_group_name_lb}."
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.security_group_name_lb }
}

resource "aws_security_group" "security_group_ec2" {
  name        = local.instance_type
  description = "Security group controlling access to ${local.instance_type}."
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.instance_type }
}

resource "aws_security_group_rule" "ec2_egress_world" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.security_group_ec2.id
  source_security_group_id = data.aws_security_group.base.id
}

resource "aws_security_group_rule" "ec2_ingress_lb_smtp" {
  type                     = "ingress"
  from_port                = local.smtp_tcp_port
  to_port                  = local.smtp_tcp_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.security_group_ec2.id
  source_security_group_id = aws_security_group.security_group_lb.id
}

resource "aws_security_group_rule" "ec2_ingress_lb_smtptls" {
  type                     = "ingress"
  from_port                = local.smtptls_tcp_port
  to_port                  = local.smtptls_tcp_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.security_group_ec2.id
  source_security_group_id = aws_security_group.security_group_lb.id
}

resource "aws_security_group_rule" "logicmonitor_ingress_snmp_tcp" {
  type                     = "ingress"
  from_port                = local.snmp_port
  to_port                  = local.snmp_trap_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.security_group_ec2.id
  source_security_group_id = data.aws_security_group.logicmonitor.id
}

resource "aws_security_group_rule" "logicmonitor_ingress_snmp_udp" {
  type                     = "ingress"
  from_port                = local.snmp_port
  to_port                  = local.snmp_trap_port
  protocol                 = "udp"
  security_group_id        = aws_security_group.security_group_ec2.id
  source_security_group_id = data.aws_security_group.logicmonitor.id
}

resource "aws_security_group_rule" "logicmonitor_ingress_icmp" {
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  security_group_id        = aws_security_group.security_group_ec2.id
  source_security_group_id = data.aws_security_group.logicmonitor.id
}

resource "aws_security_group_rule" "logicmonitor_ingress_ntp_udp" {
  type                     = "ingress"
  from_port                = local.ntp_udp_port
  to_port                  = local.ntp_udp_port
  protocol                 = "udp"
  security_group_id        = aws_security_group.security_group_ec2.id
  source_security_group_id = data.aws_security_group.logicmonitor.id
}

