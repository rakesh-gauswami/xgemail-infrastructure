resource "aws_elb" "elb" {
  name              = local.instance_type
  subnets           = [local.input_param_public_subnet_ids]
  security_groups   = [aws_security_group.security_group_lb]

  listener {
    instance_port     = 25
    instance_protocol = "tcp"
    lb_port           = 25
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 25
    target              = "TCP:25"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 300
}

resource "aws_proxy_protocol_policy" "smtp" {
  load_balancer  = aws_elb.elb.name
  instance_ports = ["25"]
}
