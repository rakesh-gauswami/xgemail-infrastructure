# vim: autoindent expandtab shiftwidth=2 filetype=terraform

# ----------------------------------------------------
# Multi EIP Lambda Execution IAM Role and Policies
# ----------------------------------------------------

data "aws_iam_policy_document" "multi_eip_rotation_lambda_trust" {
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

resource "aws_iam_role" "multi_eip_rotation_lambda_execution_role" {
  name               = "multi-eip-rotation-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.multi_eip_rotation_lambda_trust.json
}

data "aws_iam_policy_document" "multi_eip_rotation_lambda_execution_role_policy" {
  policy_id = "multi-eip-rotation-lambda-execution-role-policy"

  statement {
    sid = "MultiEipRotationASG"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:UpdateAutoScalingGroup"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "MultiEipRotationLambda"
    actions = [
      "lambda:*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "MultiEipRotationLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "MultiEipRotationEc2"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:AssociateAddress",
      "ec2:CreateTags",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DisassociateAddress"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "MultiEipRotationSsm"
    actions = [
      "ssm:DescribeDocument",
      "ssm:GetCommandInvocation",
      "ssm:ListInstanceAssociations",
      "ssm:ListCommands",
      "ssm:SendCommand"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "multi_eip_rotation_lambda_execution_role_policy" {
  name   = "multi-eip-rotation-lambda-execution-policy"
  role   = aws_iam_role.multi_eip_rotation_lambda_execution_role.id
  policy = data.aws_iam_policy_document.multi_eip_rotation_lambda_execution_role_policy.json
}

# ----------------------------------------------------
# Multi EIP Rotation Event Rule IAM Role and Policy
# ----------------------------------------------------

data "aws_iam_policy_document" "multi_eip_rotation_ssm_automation_trust" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "ssm.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "multi_eip_rotation_ssm_automation_role" {
  name               = "multi-eip-rotation-event-role"
  assume_role_policy = data.aws_iam_policy_document.multi_eip_rotation_ssm_automation_trust.json
}

data "aws_iam_policy_document" "multi_eip_rotation_event_policy" {
  policy_id = "multi-eip-rotation-event-policy"

  statement {
    sid = "MultiEipRotationEventIam"
    actions = [
      "iam:PassRole"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "MultiEipRotationEventLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "MultiEipRotationEventLambda"
    actions = [
      "lambda:InvokeFunction"
    ]
    effect = "Allow"
    resources = [
      aws_lambda_function.multi_eip_rotation_lambda.arn
    ]
  }
}

resource "aws_iam_role_policy" "multi_eip_rotation_event_policy" {
  name   = "multi-eip-rotation-event-policy"
  role   = aws_iam_role.multi_eip_rotation_ssm_automation_role.id
  policy = data.aws_iam_policy_document.multi_eip_rotation_event_policy.json
}