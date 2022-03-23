# vim: autoindent expandtab shiftwidth=2 filetype=terraform

##  Multi EIP lifecycle launching event rule and target
locals {
  multi_eip_lifecycle_event_rule_pattern = {
    "source": [
      "aws.autoscaling"
    ],
    "account": [
      local.account_id
    ],
    "region": [
      local.input_param_primary_region
    ],
    "detail-type": [
      "EC2 Instance-launch Lifecycle Action"
    ],
    "detail": {
      "LifecycleHookName": [
        local.input_param_asg_customer_delivery_lifecycle_hook_launching,
        local.input_param_asg_customer_xdelivery_lifecycle_hook_launching,
        local.input_param_asg_delta_delivery_lifecycle_hook_launching,
        local.input_param_asg_delta_xdelivery_lifecycle_hook_launching,
        local.input_param_asg_internet_delivery_lifecycle_hook_launching,
        local.input_param_asg_internet_xdelivery_lifecycle_hook_launching,
        local.input_param_asg_mf_inbound_delivery_lifecycle_hook_launching,
        local.input_param_asg_mf_inbound_xdelivery_lifecycle_hook_launching,
        local.input_param_asg_mf_outbound_delivery_lifecycle_hook_launching,
        local.input_param_asg_mf_outbound_xdelivery_lifecycle_hook_launching,
        local.input_param_asg_risky_delivery_lifecycle_hook_launching,
        local.input_param_asg_risky_xdelivery_lifecycle_hook_launching
      ],
      "LifecycleTransition": [
        "autoscaling:EC2_INSTANCE_LAUNCHING"
      ]
    }
  }
}

resource "aws_cloudwatch_event_rule" "multi_eip_lifecycle_event_rule" {
  name        = "multi-eip-lifecycle-event-rule"
  description = "Capture ASG Instance Launching"

  event_pattern = jsonencode(local.multi_eip_lifecycle_event_rule_pattern)
}

resource "aws_cloudwatch_event_target" "multi_eip_lifecycle_event_target" {
  target_id = "multi-eip-lifecycle-event-target"
  arn       = aws_lambda_function.multi_eip_rotation_lambda.arn
  rule      = aws_cloudwatch_event_rule.multi_eip_lifecycle_event_rule.id
}

##  Multi EIP rotation scheduled event rule and target

resource "aws_cloudwatch_event_rule" "multi_eip_rotation_scheduled_event_rule" {
  name        = "multi-eip-rotation-scheduled-event-rule"
  description = "Scheduled Cloudwatch Event for Multi EIP Rotation"

  schedule_expression = var.multi_eip_rotation_schedule
  is_enabled          = var.multi_eip_rotation_schedule_enabled
}

resource "aws_cloudwatch_event_target" "multi_eip_rotation_scheduled_event_target" {
  target_id = "multi-eip-rotation-scheduled-event-target"
  arn       = aws_lambda_function.multi_eip_rotation_lambda.arn
  rule      = aws_cloudwatch_event_rule.multi_eip_rotation_scheduled_event_rule.id
}
