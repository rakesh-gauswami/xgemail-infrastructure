locals {
  logicmonitor_sg_name = "logicmonitor"
  ntp_udp_port            = 123
  snmp_port               = 161
  snmp_trap_port          = 162
}

resource "aws_security_group" "logicmonitor" {
  name        = local.logicmonitor_sg_name
  description = "Security group used by Logic Monitor Collector."
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.logicmonitor_sg_name }
}

resource "aws_security_group_rule" "logicmonitor_ingress_snmp_tcp" {
  type              = "ingress"
  from_port         = local.snmp_port
  to_port           = local.snmp_trap_port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.logicmonitor.id
}

resource "aws_security_group_rule" "logicmonitor_ingress_snmp_udp" {
  type              = "ingress"
  from_port         = local.snmp_port
  to_port           = local.snmp_trap_port
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.logicmonitor.id
}

resource "aws_security_group_rule" "logicmonitor_ingress_icmp" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  self              = true
  security_group_id = aws_security_group.logicmonitor.id
}

resource "aws_security_group_rule" "logicmonitor_ingress_ntp_udp" {
  type              = "ingress"
  from_port         = local.ntp_udp_port
  to_port           = local.ntp_udp_port
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.logicmonitor.id
}
