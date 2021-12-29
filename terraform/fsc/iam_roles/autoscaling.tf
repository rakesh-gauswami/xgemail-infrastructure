resource "aws_iam_role" "autoscaling_role" {
  name_prefix        = "AutoScalingRole-"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.autoscaling_assume_role_policy.json

  tags = {
    Name = "AutoScalingRole"
  }

  lifecycle {
    create_before_destroy = true
  }
}

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

    sid = "AutoscalingSnsPolicy"
  }
  statement {
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    effect = "Allow"

    resources = ["arn:aws:sqs:${local.input_param_primary_region}:${local.input_param_account_id}:*"]

    sid = "AutoscalingSqsPolicy"
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
