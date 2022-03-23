# vim: autoindent expandtab shiftwidth=2 filetype=terraform

output "logs_sophos_central_bucket_name" {
  value = module.logs_bucket.bucket_name
}

output "logs_sophos_central_bucket_arn" {
  value = module.logs_bucket.bucket_arn
}

output "logs_sophos_central_bucket_kms_alias_arn" {
  value = module.logs_bucket.bucket_kms_key_alias_arn
}

output "logs_sophos_central_bucket_kms_key_arn" {
  value = module.logs_bucket.bucket_kms_key_arn
}

output "log_shipping_firehose_stream" {
  value = aws_kinesis_firehose_delivery_stream.log_shipping_firehose_stream.arn
}

output "firehose_writer_policy_arn" {
  value = aws_iam_policy.firehose_writer_policy.arn
}

output "cloudwatch_logs_firehose_role" {
  value = aws_iam_role.cloudwatch_logs_firehose_role.arn
}

output "zzz_output_parameter_names" {
  value = keys(
    merge(
      module.output_string_parameters.parameters,
      module.logs_bucket.output_parameters
    )
  )
}
