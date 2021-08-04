resource "aws_sns_topic" "sns_topic" {
  name = var.topic_name
  tags = local.common_tags
}
