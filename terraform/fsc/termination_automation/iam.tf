# vim: autoindent expandtab shiftwidth=2 filetype=terraform

# ----------------------------------------------------
# SSM Automation IAM Role and Policies
# ----------------------------------------------------

resource "aws_iam_role" "termination_automation_role" {
  name = "termination_automation_role"
  assume_role_policy = data.aws_iam_policy_document.termination_automation_trust_policy.json
}

data "aws_iam_policy_document" "termination_automation_trust_policy" {
  policy_id = "termination_automation_trust_policy"

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

data "aws_iam_policy_document" "termination_automation_policy" {
  policy_id = "termination_automation_policy"

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
    sid = "AutoScalingPermissions"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "Ec2Permissions"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeInstances",
      "ec2:DeleteVolume",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:DeleteVolume",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "SnsTopicPermissions"
    effect = "Allow"
    actions = [
      "sns:GetSubscriptionAttributes",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTopics",
      "sns:Publish",
      "sns:Unsubscribe",
    ]
    resources = [
      "*"
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

resource "aws_iam_role_policy" "termination_automation_policy" {
  name   = "termination-automation-policy"
  role   = aws_iam_role.termination_automation_role.id
  policy = data.aws_iam_policy_document.termination_automation_policy.json
}

# ----------------------------------------------------
# Event Rules IAM Role and Policies
# ----------------------------------------------------

resource "aws_iam_role" "events_rule_ssm_automation_role" {
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
    effect    = "Allow"
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
