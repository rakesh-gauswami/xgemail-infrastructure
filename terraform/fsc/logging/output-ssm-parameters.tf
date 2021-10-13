
module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/logging/firehose-stream/arn"
      value       = aws_kinesis_firehose_delivery_stream.log_shipping_firehose_stream.arn
      description = "Log Shipping Firehose ARN"
    },
    {
      name        = "/central/logging/firehose-stream/name"
      value       = aws_kinesis_firehose_delivery_stream.log_shipping_firehose_stream.name
      description = "Log Shipping Firehose Name"
    },
    {
      name        = "/central/logging/iam/policies/firehose-writer/arn"
      value       = aws_iam_policy.firehose_writer_policy.arn
      description = "Policy ARN for Log Shipping Firehose Writer"
    },
    {
      name        = "/central/logging/iam/roles/cloudwatch-logs-firehose-role/arn"
      value       = aws_iam_role.cloudwatch_logs_firehose_role.arn
      description = "Role ARN for CloudWatch Logs to Firehose Writer"
    }
  ]
}
