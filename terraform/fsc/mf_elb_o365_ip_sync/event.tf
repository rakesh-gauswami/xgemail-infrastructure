resource "aws_cloudwatch_event_rule" "mf_elb_o365_ip_sync_scheduled_event_rule" {
  name        = "mf-elb-o365-ip-sync-scheduled-event-rule"
  description = "Scheduled Cloudwatch Event for Mf Elb O365 Ip Sync"

  schedule_expression = "cron(0 6 * * ? *)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "mf_elb_o365_ip_sync_scheduled_event_target" {
  target_id = "mf-elb-o365-ip-sync-scheduled-event-target"
  arn       = aws_lambda_function.mf_elb_o365_ip_sync_lambda.arn
  rule      = aws_cloudwatch_event_rule.mf_elb_o365_ip_sync_scheduled_event_rule.id
}
