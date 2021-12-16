resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.example.com"
  type    = "CNAME"
  ttl     = "000"
  records = [aws_elb.elb.public_ip]
}
