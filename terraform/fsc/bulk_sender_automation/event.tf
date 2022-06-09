resource "aws_cloudwatch_event_rule" "bulk_sender_automation_scheduled_event_rule" {
  name        = "bulk-sender-automation-scheduled-event-rule"
  description = "Scheduled Cloudwatch Event for Bulk Sender Automation"

  schedule_expression = var.bulk_sender_automation_schedule
  is_enabled          = var.bulk_sender_automation_schedule_enabled
}

resource "aws_cloudwatch_event_target" "bulk_sender_automation_scheduled_event_target" {
  target_id   = "BulkSenderAutomation"
  arn         = "arn:aws:ssm:${local.input_param_primary_region}:${local.input_param_account_id}:automation-definition/${aws_ssm_document.bulk_sender_automation.name}"
  rule        = aws_cloudwatch_event_rule.bulk_sender_automation_scheduled_event_rule.id
  role_arn    = aws_iam_role.events_rule_bulk_sender_automation_role.arn
}
