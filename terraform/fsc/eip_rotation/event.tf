# vim: autoindent expandtab shiftwidth=2 filetype=terraform

##  EIP lifecycle launching event rule and target

resource "aws_cloudwatch_event_rule" "eip_rotation_event_rule" {
  name        = "eip-rotation-lifecycle-event-rule"
  description = "Capture ASG Instance Launching"

  event_pattern = <<EOF
{
    "source": [
      "aws.autoscaling"
    ],
    "account": [
      ${local.account_id}
    ],
    "region": [
      ${local.input_param_primary_region}
    ],
    "detail-type": [
      "EC2 Instance-launch Lifecycle Action"
    ],
    "detail": {
      "LifecycleHookName": ${join(var.lifecycle_hook_names)},
      "LifecycleTransition": [
        "autoscaling:EC2_INSTANCE_LAUNCHING"
      ]
    }
  }
EOF
}

resource "aws_cloudwatch_event_target" "eip_lifecycle_event_target" {
  target_id = "eip-lifecycle-event-target"
  arn       = aws_lambda_function.eip_rotation_lambda.arn
  rule      = aws_cloudwatch_event_rule.eip_rotation_event_rule.id
}