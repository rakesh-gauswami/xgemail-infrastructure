
#CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "eip_rotation" {
  name        = "eip-rotation"
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
