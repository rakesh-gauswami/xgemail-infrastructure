module "output_string_parameters" {
  source = "../modules/output_string_parameters"

  providers = {
    aws = aws.parameters
  }

  parameters = [
    {
      name        = "/central/sns/alarm-topic/arn"
      value       = aws_sns_topic.alarm_topic.arn
      description = "Alarm SNS Topic ARN"
    },

    {
      name        = "/central/sns/notification-topic/arn"
      value       = aws_sns_topic.notification_topic.arn
      description = "Notification SNS Topic ARN"
    },

    {
      name        = "/central/sns/lifecycle-topic/arn"
      value       = aws_sns_topic.lifecycle_topic.arn
      description = "lifecycle SNS Topic ARN"
    },

    {
      name        = "/central/sqs/lifecycle-queue/arn"
      value       = aws_sqs_queue.lifecycle_queue.arn
      description = "lifecycle SQS Queue ARN"
    },

    {
      name        = "/central/sqs/lifecycle-queue/name"
      value       = aws_sqs_queue.lifecycle_queue.id
      description = "lifecycle SQS Queue Name"
    }
  ]
}
