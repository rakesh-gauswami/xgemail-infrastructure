# ----------------------------------------------------
# SSM Automation IAM Role and Policies
# ----------------------------------------------------

resource "aws_iam_role" "bulk_sender_automation_role" {
  name = "bulk_sender_automation_role"
  assume_role_policy = data.aws_iam_policy_document.bulk_sender_automation_trust_policy.json
}

data "aws_iam_policy_document" "bulk_sender_automation_trust_policy" {
  policy_id = "bulk_sender_automation_trust_policy"

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

data "aws_iam_policy_document" "bulk_sender_automation_policy" {
  policy_id = "bulk_sender_automation_policy"

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
    sid = "Ec2Permissions"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
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

resource "aws_iam_role_policy" "bulk_sender_automation_policy" {
  name   = "bulk-sender-automation-policy"
  role   = aws_iam_role.bulk_sender_automation_role.id
  policy = data.aws_iam_policy_document.bulk_sender_automation_policy.json
}

# ----------------------------------------------------
# Event Rules IAM Role and Policies
# ----------------------------------------------------

resource "aws_iam_role" "events_rule_bulk_sender_automation_role" {
  name               = "BulkSenderAutomation"
  assume_role_policy = data.aws_iam_policy_document.events_rule_bulk_sender_automation_trust.json
}

data "aws_iam_policy_document" "events_rule_bulk_sender_automation_trust" {
  policy_id = "events_rule_bulk_sender_automation_trust"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "events_rule_bulk_sender_automation_policy" {
  policy_id = "events_rule_bulk_sender_automation"

  statement {
    sid    = "SsmAutomationDocumentExecution"
    effect = "Allow"
    actions = [
      "ssm:DescribeAutomationExecutions",
      "ssm:DescribeAutomationStepExecutions",
      "ssm:DescribeDocument",
      "ssm:GetAutomationExecution",
      "ssm:GetDocument",
      "ssm:StartAutomationExecution"
    ]
    resources = [
      "arn:aws:ssm:${local.input_param_primary_region}:${local.input_param_account_id}:automation-definition/${aws_ssm_document.bulk_sender_automation.name}:$DEFAULT",
    ]
  }
}

resource "aws_iam_role_policy" "events_rule_bulk_sender_automation_policy" {
  name   = "events_rule_bulk_sender_automation_policy"
  role   = aws_iam_role.events_rule_bulk_sender_automation_role.id
  policy = data.aws_iam_policy_document.events_rule_bulk_sender_automation_policy.json
}
