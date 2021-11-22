output "alarm_topic_arn" {
  value = aws_sns_topic.alarm_topic.arn
}

output "notification_topic_arn" {
  value = aws_sns_topic.notification_topic.arn
}

output "lifecycle_topic_arn" {
  value = aws_sns_topic.lifecycle_topic.arn
}

output "lifecycle_queue_arn" {
  value = aws_sqs_queue.lifecycle_queue.arn
}

output "lifecycle_queue_name" {
  value = aws_sqs_queue.lifecycle_queue.id
}

output "zzz_output_parameter_names" {
  value = keys(
    module.output_string_parameters.parameters
  )
}
