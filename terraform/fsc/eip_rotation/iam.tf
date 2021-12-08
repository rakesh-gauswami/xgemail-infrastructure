# ----------------------------------------------------
# Eip Rotation Lambda Execution IAM Role and policy
# ----------------------------------------------------
data "aws_iam_policy_document" "eip_rotation_lambda_assume_role_policy" {
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
  name = local.eip_rotation_lambda_name
  assume_role_policy = data.aws_iam_policy_document.eip_rotation_lambda_assume_role_policy.json
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

# ----------------------------------------------------
# SSM Automation IAM Role and Policies
# ----------------------------------------------------
resource "aws_iam_role" "eip_rotation_role" {
  name = "eip_rotation_role"
  assume_role_policy = data.aws_iam_policy_document.eip_rotation_trust_policy.json
}

data "aws_iam_policy_document" "eip_rotation_trust_policy" {
  policy_id = "eip_rotation_trust_policy"

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ssm.amazonaws.com"
      ]
    }
  }
}

# ----------------------------------------------------
# Event Rules IAM Role and Policies
# ----------------------------------------------------

resource "aws_iam_role" "events_rule_eip_rotation_role" {
  name               = "EIPLifecycle"
  assume_role_policy = data.aws_iam_policy_document.events_rule_eip_rotation_trust.json
}

data "aws_iam_policy_document" "events_rule_eip_rotation_trust" {
  policy_id = "events_rule_eip_rotation_trust"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "events_rule_eip_rotation_policy" {
  policy_id = "events_rule_eip_rotation"

  statement {
    sid = "EipRotationLambda"
    effect    = "Allow",
    actions   = [
      "lambda:*",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid = "CloudWatchLogGroup"
    actions = [
      "logs:CreateLogGroup",
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:logs:${local.input_param_primary_region}:*:*"
    ]
  }
  statement {
    sid = "CloudWatchLogStream"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:logs:${local.input_param_primary_region}:*:log-group:*:*"
    ]
  }

  statement {
    sid = "Ec2Permissions"
    effect    = "Allow"
    actions   = [
      "ec2:CreateTags",
      "ec2:DescribeAddresses",
      "ec2:AssociateAddress",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DisassociateAddress"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "events_rule_eip_rotation_policy" {
  name   = "events_rule_eip_rotation_policy"
  role   = aws_iam_role.events_rule_eip_rotation_role.id
  policy = data.aws_iam_policy_document.events_rule_eip_rotation_policy.json
}