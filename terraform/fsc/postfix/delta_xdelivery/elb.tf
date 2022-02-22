resource "aws_elb" "elb" {
  name            = local.instance_type
  subnets         = local.input_param_private_subnet_ids
  security_groups = [aws_security_group.security_group_lb.id]
  internal        = true

  listener {
    instance_port     = 8025
    instance_protocol = "tcp"
    lb_port           = 8025
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    target              = "TCP:8025"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 60
  connection_draining         = true
  connection_draining_timeout = 120
}

resource "aws_load_balancer_policy" "elb_policy" {
  load_balancer_name = aws_elb.elb.name
  policy_name        = "ELBSSLNegotiationPolicy"
  policy_type_name   = "SSLNegotiationPolicyType"

  policy_attribute {
    name  = "Reference-Security-Policy"
    value = "ELBSecurityPolicy-2016-08"
  }
}