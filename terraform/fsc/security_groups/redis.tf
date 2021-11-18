locals {
  redis_sg_name   = "redis"
  redis_tcp_port  = 6379
}

resource "aws_security_group" "redis" {
  name        = local.redis_sg_name
  description = "The default security group used by Redis instances."
  vpc_id      = local.input_param_vpc_id

  tags = { Name = local.redis_sg_name }
}

resource "aws_security_group_rule" "redis_ingress_tcp" {
  type              = "ingress"
  from_port         = local.redis_tcp_port
  to_port           = local.redis_tcp_port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.logicmonitor.id
}
