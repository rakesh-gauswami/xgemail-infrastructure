data "aws_iam_policy_document" "autoscaling_policy" {
  policy_id = "autoscaling_policy"

  statement {
    actions = [
      "sns:Publish",
    ]

    effect = "Allow"

    resources = [
      "arn:aws:sns:${local.input_param_primary_region}:${local.input_param_account_id}:*"
    ]

    sid = "autoscaling_sns_policy"
  }
  statement {
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    effect = "Allow"

    resources = ["arn:aws:sqs:${local.input_param_primary_region}:${local.input_param_account_id}:*"]

    sid = "autoscaling_sqs_policy"
  }
}

resource "aws_iam_policy" "autoscaling_policy" {
  name_prefix = "AutoScalingPolicy-"
  path        = "/"
  description = "Policy for AutoScaling"
  policy      = data.aws_iam_policy_document.autoscaling_policy.json

  tags = { Name = "AutoScalingPolicy" }

  lifecycle {
    create_before_destroy = true
  }
}
