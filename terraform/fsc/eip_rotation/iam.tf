# Eip Rotation Lambda Execution Role

data "aws_iam_policy_document" "eip_rotation_lambda_execution_role_policy" {
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

resource "aws_iam_role" "eip_rotation_lambda_execution_role" {
  name_prefix = local.eip_rotation_prefix
  assume_role_policy = data.aws_iam_policy_document.eip_rotation_lambda_execution_role_policy.json
}

data "aws_iam_policy_document" "eip_rotation_lambda_execution_role_policy" {
  statement {
    sid = "EipRotationAutoScalingRolePolicy"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:UpdateAutoScalingGroup",
    ]
    effect    = "Allow"
    resources = [
     "*"
    ]
  }
  statement {
    sid = "EipRotationLambda"
    actions = [
      "lambda:*",
    ]
    effect    = "Allow"
    resources = [
      "*"
    ]
  }
  statement {
    sid = "EipRotationCloudWatchLogStream"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = [
      "*"
    ]
  }
  statement {
    sid = "EipRotationEc2"
    actions = [
      "ec2:AssociateAddress",
      "ec2:CreateTags",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DisassociateAddress",
    ]
    effect    = "Allow"
    resources = [
      "*"
    ]
  }
  statement {
    sid = "EipRotationSsmStream"
    actions = [
      "ssm:DescribeDocument",
      "ssm:GetCommandInvocation",
      "ssm:ListInstanceAssociations",
      "ssm:ListCommands",
      "ssm:SendCommand",
    ]
    effect    = "Allow"
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "eip_rotation_lambda_execution_role_policy" {
  name   = "eip_rotation_lambda_execution_role_policy"
  role   = aws_iam_role.eip_rotation_lambda_execution_role.id
  policy = data.aws_iam_policy_document.eip_rotation_lambda_execution_role_policy.json
}
