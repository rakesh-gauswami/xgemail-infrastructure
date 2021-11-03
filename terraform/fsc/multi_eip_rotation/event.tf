# vim: autoindent expandtab shiftwidth=2 filetype=terraform

resource "aws_cloudwatch_event_rule" "multi_eip_rotation" {
  name        = "multi-eip-rotation-lifecycle-launching"
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

resource "aws_cloudwatch_event_target" "multi_eip_rotation" {
  target_id = "multi-eip-rotation-lifecycle-launching"
  arn  = aws_lambda_function.multi_eip_rotation_lambda.arn
  rule = aws_cloudwatch_event_rule.multi_eip_rotation.id
}