data "aws_route53_zone" "hosted_zone" {
  zone_id = local.input_param_zone_id
}

resource "aws_route53_record" "encryption-delivery" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${local.instance_type}-cloudemail-${local.input_param_zone_fqdn}"
  type    = "CNAME"
  ttl     = "900"
  records = [aws_elb.elb.dns_name]
}