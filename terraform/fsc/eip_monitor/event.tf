resource "aws_cloudwatch_event_rule" "eip_monitor_scheduled_event_rule" {
  name        = "eip-monitor-scheduled-event-rule"
  description = "Scheduled Cloudwatch Event for EIP Monitor"

  schedule_expression = var.eip_monitor_schedule
  is_enabled          = var.eip_monitor_schedule_enabled
}

resource "aws_cloudwatch_event_target" "eip_monitor_scheduled_event_target" {
  target_id = "eip-monitor-scheduled-event-target"
  arn       = aws_lambda_function.eip_monitor_lambda.arn
  rule      = aws_cloudwatch_event_rule.eip_monitor_scheduled_event_rule.id
}
