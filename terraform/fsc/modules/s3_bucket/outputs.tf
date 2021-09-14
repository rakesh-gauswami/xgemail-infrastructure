# vim: autoindent expandtab shiftwidth=2 filetype=terraform

output "bucket" {
  value = aws_s3_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

output "bucket_kms_key_alias_arn" {
  value = var.should_create_kms_key ? module.kms_key[0].key_alias_arn : null
}

output "bucket_kms_key_arn" {
  value = var.should_create_kms_key ? module.kms_key[0].key_arn : null
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.id
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.bucket.bucket_regional_domain_name
}

output "output_parameters" {
  value = merge(
    module.output_string_parameters.parameters,
    var.should_create_kms_key ? module.kms_key[0].output_parameters : {}
  )
}
