data "aws_route53_zone" "hosted_zone" {
  zone_id = local.input_param_zone_id
}

resource "aws_route53_record" "internet_delivery" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "outbound.${local.input_param_zone_fqdn}"
  type    = "A"
  ttl     = "900"
  records = [aws_elb.elb.dns_name]
}