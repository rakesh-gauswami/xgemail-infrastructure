output "sns_topic_arn" {
  value = aws_sns_topic.sns_topic.arn
}

output "output_parameters" {
  value = merge(
    module.output_string_parameters.parameters,
    var.should_create_kms_key ? module.kms_key[0].output_parameters : {}
  )
}
