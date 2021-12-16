locals {

        Environment:                    "{{account.name}}"
      ExternalPort:                   "25"
      HealthCheckInterval:            "60"
      HealthCheckTarget:              "TCP:25"
      HealthCheckUnhealthyThreshold:  "10"
      HostAlarmTopicARN:              "{{sns.arn_prefix}}{{sns.alarm_sns_topic}}"
      LoadBalancerName:               "{{ec2.elb.cs}}"
      SecurityGroupLb:                "{{cloud_email_sg_output.ansible_facts.cloudformation[stack.ec2.sg.cloud_email_security_groups].stack_outputs.XgemailCustomerSubmitSecurityGroupLb}}"
      Subnets:                        "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.VpcZoneIdentifiersPublic}}"
      Vpc:                            "{{cloud_email_vpc_output.ansible_facts.cloudformation[stack.vpc.cloud_email_vpc].stack_outputs.Vpc}}"

}

resource "aws_elb" "elb" {
  name              = "customer-submit"
  subnets           = [local.input_param_public_subnet_ids]
  security_groups   = [aws_security_group.security_group_lb]

  listener {
    instance_port     = 25
    instance_protocol = "tcp"
    lb_port           = 25
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 587
    instance_protocol = "tcp"
    lb_port           = 587
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 25
    target              = "TCP:25/"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 300
}

resource "aws_proxy_protocol_policy" "smtp" {
  load_balancer  = aws_elb.elb.name
  instance_ports = ["25", "587"]
}
