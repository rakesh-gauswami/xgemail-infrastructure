data "aws_route53_zone" "hosted_zone" {
  zone_id = local.input_param_zone_id
}

resource "aws_route53_record" "mx_01" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "mx-01.${local.input_param_zone_fqdn}"
  type    = "A"
  ttl     = "900"
  records = [aws_elb.elb.dns_name]
}

resource "aws_route53_record" "mx_02" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "mx-02.${local.input_param_zone_fqdn}"
  type    = "A"
  ttl     = "900"
  records = [aws_elb.elb.dns_name]
}