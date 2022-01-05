# vim: autoindent expandtab shiftwidth=2 filetype=terraform

resource "aws_cloudwatch_event_rule" "termination_automation" {
  name        = "termination-automation"
  description = "Capture ASG Instance Termination"

  event_pattern = <<DOC
  {
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
      "EC2 Instance-terminate Lifecycle Action"
    ],
    "detail": {
      "LifecycleHookName": ["${local.input_param_asg_delta_delivery_lifecycle_hook_terminating}","${local.input_param_asg_encryption_delivery_lifecycle_hook_terminating}","${local.input_param_asg_encryption_submit_lifecycle_hook_terminating}","${local.input_param_asg_customer_delivery_lifecycle_hook_terminating}","${local.input_param_asg_internet_submit_lifecycle_hook_terminating}","${local.input_param_asg_mf_inbound_delivery_lifecycle_hook_terminating}","${local.input_param_asg_mf_inbound_submit_lifecycle_hook_terminating}","${local.input_param_asg_mf_outbound_delivery_lifecycle_hook_terminating}","${local.input_param_asg_mf_outbound_submit_lifecycle_hook_terminating}","${local.input_param_asg_internet_delivery_lifecycle_hook_terminating}","${local.input_param_asg_customer_submit_lifecycle_hook_terminating}","${local.input_param_asg_risky_delivery_lifecycle_hook_terminating}","${local.input_param_asg_warmup_delivery_lifecycle_hook_terminating}"],
      "LifecycleTransition": [
        "autoscaling:EC2_INSTANCE_TERMINATING"
      ]
    }
  }
DOC
}

resource "aws_cloudwatch_event_target" "termination_automation" {
  target_id = "termination-automation"
  arn  = "arn:aws:ssm:${local.input_param_primary_region}:${local.account_id}:automation-definition/${aws_ssm_document.termination_automation.name}"
  rule = aws_cloudwatch_event_rule.termination_automation.id
  role_arn = aws_iam_role.termination_automation_event_rule_role.arn

  input_transformer {
    input_paths = {
      "region" : "$.region",
      "time" : "$.time",
      "autocaling_group_name" : "$.detail.AutoScalingGroupName",
      "instance_id" : "$.detail.EC2InstanceId",
      "lifecycle_hook_name" : "$.detail.LifecycleHookName",
      "lifecycle_action_token" : "$.detail.LifecycleActionToken",
    }
    input_template = jsonencode({"Region":[<region>], "Time":[<time>], "AutoScalingGroupName":[<autocaling_group_name>], "InstanceId":[<instance_id>], "LifecycleHookName":[<lifecycle_hook_name>], "LifecycleActionToken":[<lifecycle_action_token>]}
  }
}
