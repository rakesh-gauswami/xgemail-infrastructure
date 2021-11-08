# vim: autoindent expandtab shiftwidth=2 filetype=terraform

# ----------------------------------------------------
# SSM Automation IAM Role and Policies
# ----------------------------------------------------

data "aws_iam_policy_document" "multi_eip_rotation_assume_role_policy" {
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

resource "aws_iam_role" "multi_eip_rotation_lambda_execution_role" {
  name = "multi-eip-rotation-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.multi_eip_rotation_assume_role_policy.json
}

data "aws_iam_policy_document" "multi_eip_rotation_lambda_execution_role_policy" {
  policy_id = "multi-eip-rotation-lambda-execution-role-policy"

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "LambdaPermissions"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
    ]
    resources = [
      aws_lambda_function.multi_eip_rotation_lambda.arn
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
    sid = "SsmAutomationPermissions"
    effect = "Allow"
    actions = [
      "ssm:DescribeAutomationExecutions",
      "ssm:DescribeAutomationStepExecutions",
      "ssm:DescribeDocument",
      "ssm:DescribeInstanceInformation",
      "ssm:GetAutomationExecution",
      "ssm:GetCommandInvocation",
      "ssm:GetConnectionStatus",
      "ssm:GetDocument",
      "ssm:ListCommandInvocations",
      "ssm:ListCommands",
      "ssm:ListInstanceAssociations",
      "ssm:ListDocuments",
      "ssm:ListDocumentVersions",
      "ssm:SendCommand",
      "ssm:StartAutomationExecution",
    ]
    resources = [
      "*"
    ]
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

resource "aws_iam_role" "multi_eip_rotation_event_role" {
  name               = "SSMLifecycle"
  assume_role_policy = data.aws_iam_policy_document.events_rule_ssm_automation_trust.json
}

data "aws_iam_policy_document" "events_rule_ssm_automation_trust" {
  policy_id = "events_rule_ssm_automation_trust"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "events_rule_ssm_automation_policy" {
  policy_id = "events_rule_ssm_automation"

  statement {
    sid = "SsmAutomationPermissions"
    effect    = "Allow",
    actions   = [
      "ssm:*",
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
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "events_rule_ssm_automation_policy" {
  name   = "events_rule_ssm_automation_policy"
  role   = aws_iam_role.events_rule_ssm_automation_role.id
  policy = data.aws_iam_policy_document.events_rule_ssm_automation_policy.json
}