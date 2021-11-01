# vim: autoindent expandtab shiftwidth=2 filetype=terraform
locals {
  alarm_topic_name          = "alarm-topic"
  lifecycle_queue_name      = "lifecycle-queue"
  lifecycle_topic_name      = "lifecycle-topic"
  notification_topic_name   = "notification-topic"
  mailops_email_address     = "SophosMailOps@sophos.com"

  default_message_retention  = 1209600
}

resource "aws_sns_topic" "alarm_topic" {
  name = local.alarm_topic_name

  tags = { Name = local.alarm_topic_name }
}

resource "aws_sns_topic" "lifecycle_topic" {
  name = local.lifecycle_topic_name

  tags = { Name = local.lifecycle_topic_name }
}

resource "aws_sns_topic" "notification_topic" {
  name = local.notification_topic_name

  tags = { Name = local.notification_topic_name }
}

resource "aws_sqs_queue" "lifecycle_queue" {
  name = local.lifecycle_queue_name

  message_retention_seconds   = local.default_message_retention

  tags = {
    Name                    = local.lifecycle_queue_name
    infrastructure-managed  = true
  }
}

data "aws_iam_policy_document" "lifecycle_queue_policy" {
  statement {
    sid = "LifecycleQueuePolicy"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]
    resources = [
      aws_sqs_queue.lifecycle_queue.arn,
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [
        aws_sns_topic.lifecycle_topic.arn
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "lifecycle_queue_policy" {
  queue_url = aws_sqs_queue.lifecycle_queue.id
  policy    = data.aws_iam_policy_document.lifecycle_queue_policy.json
}

# ----------------------------------------------------
# SQS Queue to SNS Topic Subscriptions
# ----------------------------------------------------

resource "aws_sns_topic_subscription" "lifecycle_queue_lifecycle_topic_subscription" {
  topic_arn = aws_sns_topic.lifecycle_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.lifecycle_queue.arn
}
resource "aws_sns_topic_subscription" "mailops_email_alarm_topic_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email-json"
  endpoint  = local.mailops_email_address
}

resource "aws_sns_topic_subscription" "mailops_email_notification_topic_subscription" {
  topic_arn = aws_sns_topic.notification_topic.arn
  protocol  = "email"
  endpoint  = local.mailops_email_address
}
