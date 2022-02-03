# vim: autoindent expandtab shiftwidth=2 filetype=terraform

##  EIP lifecycle launching event rule and target
locals {
  eip_rotation_lifecycle_event_rule_pattern = {
    "source": [
      "aws.autoscaling"
    ],
    "account": [
      "${local.account_id}"
    ],
    "region": [
      "${local.input_param_primary_region}"
    ],
    "detail-type": [
      "EC2 Instance-launch Lifecycle Action"
    ],
    "detail": {
      "LifecycleHookName": [],
      "LifecycleTransition": [
        "autoscaling:EC2_INSTANCE_LAUNCHING"
      ]
    }
  }
}

resource "aws_cloudwatch_event_rule" "eip_rotation_lifecycle_event_rule" {
  name        = "eip-rotation-lifecycle-event-rule"
  description = "Capture ASG Instance Launching"

  event_pattern = jsonencode(local.eip_rotation_lifecycle_event_rule_pattern)
}

resource "aws_cloudwatch_event_target" "eip_rotation_lifecycle_event_target" {
  target_id = "eip-lifecycle-event-target"
  arn       = aws_lambda_function.eip_rotation_lambda.arn
  rule      = aws_cloudwatch_event_rule.eip_rotation_lifecycle_event_rule.id
}

##  EIP rotation scheduled event rule and target

resource "aws_cloudwatch_event_rule" "eip_rotation_scheduled_event_rule" {
  name        = "eip-rotation-scheduled-event-rule"
  description = "Scheduled Cloudwatch Event for EIP Rotation"

  schedule_expression = var.eip_rotation_schedule
  is_enabled          = var.eip_rotation_schedule_enabled
}

resource "aws_cloudwatch_event_target" "eip_rotation_scheduled_event_target" {
  target_id = "eip-rotation-scheduled-event-target"
  arn       = aws_lambda_function.eip_rotation_lambda.arn
  rule      = aws_cloudwatch_event_rule.eip_rotation_scheduled_event_rule.id
}
