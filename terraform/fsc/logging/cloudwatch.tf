
# Firehose Delivery Stream CloudWatch Log Group
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/kinesisfirehose/${local.stream_name}"
  retention_in_days = 120
  tags = {
    Name = local.stream_name
  }
}

# Firehose Delivery Stream CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "log_stream" {
  log_group_name = aws_cloudwatch_log_group.log_group.name
  name           = "S3Delivery"
}
