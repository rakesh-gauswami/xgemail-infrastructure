
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

resource "aws_cloudwatch_event_target" "eip_rotation" {
  target_id = "eip-rotation"
  arn  = aws_lambda_function.xgemail_eip_rotation.arn
  rule = aws_cloudwatch_event_rule.eip_rotation.id

  input_transformer {
    input_paths = {
      "region" : "$.region",
      "time" : "$.time",
      "autocaling_group_name" : "$.detail.AutoScalingGroupName",
      "instance_id" : "$.detail.EC2InstanceId",
      "lifecycle_hook_name" : "$.detail.LifecycleHookName",
      "lifecycle_action_token" : "$.detail.LifecycleActionToken",
    }
    input_template = <<EOF
  {
  "Region":<region>,
  "Time":<time>,
  "AutoScalingGroupName":<autocaling_group_name>,
  "InstanceId":<instance_id>,
  "LifecycleHookName":<lifecycle_hook_name>,
  "LifecycleActionToken":<lifecycle_action_token>
  }
EOF
  }
}
