data "aws_route53_zone" "hosted_zone" {
  zone_id = local.input_param_zone_id
}

resource "aws_route53_record" "route53_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${local.instance_type}.${local.input_param_zone_fqdn}"
  type    = "CNAME"
  ttl     = "900"
  records = [aws_elb.elb.dns_name]
}
