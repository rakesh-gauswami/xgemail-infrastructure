output "key_alias_name" {
  value = aws_kms_alias.alias.name
}

output "key_alias_arn" {
  value = aws_kms_alias.alias.arn
}

output "key_arn" {
  value = aws_kms_key.key.arn
}

output "key_id" {
  value = aws_kms_key.key.key_id
}

output "output_parameters" {
  value = module.output_string_parameters.parameters
}
