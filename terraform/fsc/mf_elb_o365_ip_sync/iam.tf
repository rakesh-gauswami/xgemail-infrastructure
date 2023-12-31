data "aws_iam_policy_document" "mf_elb_o365_ip_sync_lambda_trust_policy" {
  policy_id = "mf-elb-o365-ip-sync-lambda-trust-policy"

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "mf_elb_o365_ip_sync_lambda_execution_role" {
  name               = "mf_elb_o365_ip_sync_lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.mf_elb_o365_ip_sync_lambda_trust_policy.json
}

data "aws_iam_policy_document" "mf_elb_o365_ip_sync_lambda_role_policy" {
  policy_id = "mf-elb-o365-ip-sync-lambda-role-policy"

  statement {
    sid = "CwLogsPermissions"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "Ec2Permissions"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:DescribeSecurityGroups",
      "ec2:RevokeSecurityGroupIngress"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "SsmPermissions"
    actions = [
      "ssm:GetParameter"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "mf_elb_o365_ip_sync_lambda_role_policy" {
  name   = "mf-elb-o365-ip-sync-lambda-role-policy"
  role   = aws_iam_role.mf_elb_o365_ip_sync_lambda_execution_role.id
  policy = data.aws_iam_policy_document.mf_elb_o365_ip_sync_lambda_role_policy.json
}
