locals {
  input_param_dns_zone_fqdn     = nonsensitive(data.aws_ssm_parameter.dns_zone_fqdn.value)
  input_param_dns_zone_id       = nonsensitive(data.aws_ssm_parameter.dns_zone_id.value)
  input_param_nat_public_ips    = nonsensitive(data.aws_ssm_parameter.nat_public_ips.value)
}

data "aws_ssm_parameter" "dns_zone_fqdn" {
  name      = "/central/account/dns/zone-fqdn"
  provider  = aws.parameters
}

data "aws_ssm_parameter" "dns_zone_id" {
  name      = "/central/account/dns/zone-id"
  provider  = aws.parameters
}

data "aws_ssm_parameter" "nat_public_ips" {
  name      = "/central/vpc/nat-public-ips"
  provider  = aws.parameters
}
