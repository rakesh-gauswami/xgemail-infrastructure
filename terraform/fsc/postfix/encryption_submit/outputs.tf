output "security_group_lb" {
  value = aws_security_group.security_group_lb.id
}

output "security_group_ec2" {
  value = aws_security_group.security_group_ec2.id
}
