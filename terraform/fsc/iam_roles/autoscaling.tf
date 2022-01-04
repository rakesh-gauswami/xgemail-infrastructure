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

    sid = "AutoScalingSnsPolicy"
  }
  statement {
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    effect = "Allow"

    resources = ["arn:aws:sqs:${local.input_param_primary_region}:${local.input_param_account_id}:*"]

    sid = "AutoScalingSqsPolicy"
  }
}

resource "aws_iam_role_policy" "autoscaling_policy" {
  name        = "AutoScalingPolicy"
  role        = aws_iam_role.autoscaling_role.id
  policy      = data.aws_iam_policy_document.autoscaling_policy.json
}
