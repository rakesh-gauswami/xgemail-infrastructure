resource "aws_elb" "elb" {
  name            = local.instance_type
  subnets         = local.input_param_private_subnet_ids
  security_groups = [aws_security_group.security_group_lb.id]

  listener {
    instance_port     = 8025
    instance_protocol = "tcp"
    lb_port           = 8025
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 25
    target              = "TCP:8025"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 60
  connection_draining         = true
  connection_draining_timeout = 150
}

resource "aws_proxy_protocol_policy" "smtp" {
  load_balancer  = aws_elb.elb.name
  instance_ports = ["8025"]
}