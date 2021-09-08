locals {
  nat_public_ip_a = split(",", local.input_param_nat_public_ips)[0]
  nat_public_ip_b = split(",", local.input_param_nat_public_ips)[1]
  nat_public_ip_c = split(",", local.input_param_nat_public_ips)[2]

  nat_dns_record_a = "outbound-${replace(local.nat_public_ip_a, ".", "-")}.${local.input_param_dns_zone_fqdn}"
  nat_dns_record_b = "outbound-${replace(local.nat_public_ip_b, ".", "-")}.${local.input_param_dns_zone_fqdn}"
  nat_dns_record_c = "outbound-${replace(local.nat_public_ip_c, ".", "-")}.${local.input_param_dns_zone_fqdn}"
}

resource "aws_route53_record" "nat_dns_record_a" {
  zone_id = local.input_param_dns_zone_id
  name    = local.nat_dns_record_a
  type    = "A"
  ttl     = "900"
  records = [local.nat_public_ip_a]
}

resource "aws_route53_record" "nat_dns_record_b" {
  zone_id = local.input_param_dns_zone_id
  name    = local.nat_dns_record_b
  type    = "A"
  ttl     = "900"
  records = [local.nat_public_ip_b]
}

resource "aws_route53_record" "nat_dns_record_c" {
  zone_id = local.input_param_dns_zone_id
  name    = local.nat_dns_record_c
  type    = "A"
  ttl     = "900"
  records = [local.nat_public_ip_c]
}
