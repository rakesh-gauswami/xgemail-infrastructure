locals {
  base_sg_name = "base"
}

resource "aws_security_group" "base" {
  name        = local.base_sg_name
  description = "The default security group used by all instances."
  vpc_id      = local.input_param_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = local.base_sg_name }
}
