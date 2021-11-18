data "aws_iam_policy_document" "eip_monitor_lambda_trust_policy" {
  policy_id = "eip-monitor-lambda-trust-policy"

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "eip_monitor_lambda_role" {
  name = "eip-monitor-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.eip_monitor_lambda_trust_policy.json
}

data "aws_iam_policy_document" "eip_monitor_lambda_role_policy" {
  policy_id = "eip-monitor-lambda-role-policy"

  statement {
    sid = "EipMonitorLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    sid = "EipMonitorEc2"
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeAddresses",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eip_monitor_lambda_role_policy" {
  name   = "eip-monitor-lambda-role-policy"
  role   = aws_iam_role.eip_monitor_lambda_role.id
  policy = data.aws_iam_policy_document.eip_monitor_lambda_role_policy.json
}
